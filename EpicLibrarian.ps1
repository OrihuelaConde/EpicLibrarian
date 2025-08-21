function Get-ReadableSize {
    param([long]$bytes)
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes B" }
}

function Show-Spinner {
    param(
        [scriptblock]$Action,
        [string]$Message = "Procesando..."
    )
    $spinnerChars = @('|','/','-','\')
    $job = Start-Job -ScriptBlock $Action
    $i = 0
    while ($job.State -eq 'Running') {
        Write-Host -NoNewline ("`r{0} {1}" -f $spinnerChars[$i], $Message)
        Start-Sleep -Milliseconds 150
        $i = ($i + 1) % $spinnerChars.Count
    }
    Receive-Job $job | Out-Null
    Remove-Job $job
    Write-Host "`r✔ $Message completado.        "
}

# Configuración inicial
$origen  = "C:\Program Files (x86)\Epic Games"
$destino = "D:\Epic Games"

if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino | Out-Null }

while ($true) {
    # Juegos en origen (excluyendo symlinks)
    $juegosOrigen = Get-ChildItem -Path $origen -Directory -ErrorAction SilentlyContinue |
                    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
                    ForEach-Object {
                        $sizeBytes = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                                      Measure-Object -Property Length -Sum).Sum
                        if (-not $sizeBytes) { $sizeBytes = 0 }
                        [PSCustomObject]@{
                            Nombre  = $_.Name
                            Ruta    = $_.FullName
                            Bytes   = [int64]$sizeBytes
                            Legible = Get-ReadableSize $sizeBytes
                            Ubicacion = "Origen"
                        }
                    }

    # Juegos en destino
    $juegosDestino = Get-ChildItem -Path $destino -Directory -ErrorAction SilentlyContinue |
                     ForEach-Object {
                         $sizeBytes = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                                       Measure-Object -Property Length -Sum).Sum
                         if (-not $sizeBytes) { $sizeBytes = 0 }
                         [PSCustomObject]@{
                             Nombre  = $_.Name
                             Ruta    = $_.FullName
                             Bytes   = [int64]$sizeBytes
                             Legible = Get-ReadableSize $sizeBytes
                             Ubicacion = "Destino"
                         }
                     }

    # Unir y ordenar
    $juegosConTamaño = @($juegosOrigen + $juegosDestino) | Sort-Object -Property Bytes -Descending

    if (-not $juegosConTamaño -or $juegosConTamaño.Count -eq 0) {
        Write-Host "No se encontraron juegos en ${origen} ni en ${destino}" -ForegroundColor Yellow
        break
    }

    # Mostrar lista (verde si está en destino)
    Write-Host "`nJuegos detectados (ordenados por tamaño):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $juegosConTamaño.Count; $i++) {
        if ($juegosConTamaño[$i].Ubicacion -eq "Destino") {
            Write-Host "$($i+1). $($juegosConTamaño[$i].Nombre) - $($juegosConTamaño[$i].Legible) [Destino]" -ForegroundColor Green
        } else {
            Write-Host "$($i+1). $($juegosConTamaño[$i].Nombre) - $($juegosConTamaño[$i].Legible) [Origen]"
        }
    }

    $entrada = Read-Host "Ingrese el número del juego a mover (0 para salir)"
    $idx = 0
    if (-not [int]::TryParse($entrada, [ref]$idx)) { Write-Host "Selección inválida." -ForegroundColor Red; continue }
    if ($idx -eq 0) { Write-Host "Saliendo..." -ForegroundColor Yellow; break }
    if ($idx -lt 1 -or $idx -gt $juegosConTamaño.Count) { Write-Host "Selección inválida." -ForegroundColor Red; continue }

    $juego = $juegosConTamaño[$idx - 1]
    Write-Host "Has seleccionado: $($juego.Nombre) [$($juego.Ubicacion)]" -ForegroundColor Green

    if ($juego.Ubicacion -eq "Origen") {
        # Mover de origen a destino
        $confirmar = (Read-Host "¿Mover este juego a ${destino} y crear enlace simbólico? (s/n)").ToLower()
        if ($confirmar -ne 's') { Write-Host "Operación cancelada." -ForegroundColor Yellow; continue }
        $rutaOrigen  = $juego.Ruta
        $rutaDestino = Join-Path $destino $juego.Nombre
        if (Test-Path $rutaDestino) { Write-Host "Ya existe en destino." -ForegroundColor Red; continue }

        try {
            Show-Spinner -Message "Moviendo $($juego.Nombre)" -Action {
                Move-Item -Path $using:rutaOrigen -Destination $using:rutaDestino -ErrorAction Stop
            }
        }
        catch { Write-Host "Error al mover: $_" -ForegroundColor Red; continue }

        try {
            cmd /c mklink /D "`"$rutaOrigen`"" "`"$rutaDestino`"" | Out-Null
            Write-Host "Juego movido y enlazado." -ForegroundColor Green
        }
        catch { Write-Host "Error al crear enlace simbólico: $_" -ForegroundColor Red }

    } elseif ($juego.Ubicacion -eq "Destino") {
        # Mover de destino a origen (borrar symlink)
        $rutaDestino = $juego.Ruta
        $rutaOrigen  = Join-Path $origen $juego.Nombre
        $confirmar = (Read-Host "¿Mover este juego de vuelta a ${origen} y borrar enlace simbólico? (s/n)").ToLower()
        if ($confirmar -ne 's') { Write-Host "Operación cancelada." -ForegroundColor Yellow; continue }

        # Borrar symlink si existe
        if (Test-Path $rutaOrigen) {
            try {
                Remove-Item -Path $rutaOrigen -Force
            }
            catch { Write-Host "No se pudo borrar el enlace simbólico: $_" -ForegroundColor Red; continue }
        }

        try {
            Show-Spinner -Message "Moviendo $($juego.Nombre) de vuelta" -Action {
                Move-Item -Path $using:rutaDestino -Destination $using:rutaOrigen -ErrorAction Stop
            }
            Write-Host "Juego restaurado al origen." -ForegroundColor Green
        }
        catch { Write-Host "Error al mover de vuelta: $_" -ForegroundColor Red }
    }
}