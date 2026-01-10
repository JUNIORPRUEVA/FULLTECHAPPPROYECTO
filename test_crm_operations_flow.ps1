# ============================================================================
# Script PowerShell: Prueba de Flujo CRM → Operaciones
# ============================================================================
# Este script ejecuta las pruebas automatizadas del flujo CRM → Operaciones
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Email,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "http://localhost:3000"
)

# Colores
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorInfo = "Cyan"
$ColorWarning = "Yellow"

function Write-Header {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  PRUEBA DE FLUJO CRM → OPERACIONES                                    ║" -ForegroundColor Cyan
    Write-Host "║  Verificación de creación de clientes y jobs                          ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $Title" -ForegroundColor Blue
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $ColorSuccess
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $ColorError
}

function Write-InfoMsg {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $ColorInfo
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $ColorWarning
}

# Verificar si existe Node.js
function Test-NodeInstalled {
    try {
        $null = node --version
        return $true
    } catch {
        return $false
    }
}

# Verificar si el backend está corriendo
function Test-BackendRunning {
    param([string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/health" -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Función principal
function Main {
    Write-Header
    
    # Verificar Node.js
    Write-InfoMsg "Verificando prerequisitos..."
    if (-not (Test-NodeInstalled)) {
        Write-ErrorMsg "Node.js no está instalado o no está en el PATH"
        Write-InfoMsg "Descarga Node.js desde: https://nodejs.org/"
        exit 1
    }
    Write-Success "Node.js está instalado"
    
    # Verificar backend
    Write-InfoMsg "Verificando backend en $ApiUrl..."
    if (-not (Test-BackendRunning -Url $ApiUrl)) {
        Write-WarningMsg "El backend no responde en $ApiUrl"
        Write-InfoMsg "Asegúrate de que el backend esté corriendo"
        Write-InfoMsg "Puedes iniciarlo con: cd fulltech_api && npm run dev"
        
        $continue = Read-Host "¿Deseas continuar de todas formas? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    } else {
        Write-Success "Backend está respondiendo"
    }
    
    # Solicitar credenciales si no fueron proporcionadas
    if ([string]::IsNullOrWhiteSpace($Email)) {
        Write-Host ""
        $Email = Read-Host "Ingresa tu email"
    }
    
    if ([string]::IsNullOrWhiteSpace($Password)) {
        $SecurePassword = Read-Host "Ingresa tu contraseña" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    
    # Configurar variable de entorno
    $env:API_URL = $ApiUrl
    
    # Ejecutar el script de Node.js
    Write-Section "EJECUTANDO PRUEBAS"
    Write-Host ""
    
    $scriptPath = Join-Path $PSScriptRoot "test_crm_operations_flow.js"
    
    if (-not (Test-Path $scriptPath)) {
        Write-ErrorMsg "No se encontró el script de pruebas en: $scriptPath"
        exit 1
    }
    
    try {
        node $scriptPath $Email $Password
        $exitCode = $LASTEXITCODE
        
        Write-Host ""
        if ($exitCode -eq 0) {
            Write-Success "Todas las pruebas pasaron exitosamente"
            Write-Host ""
            Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host "  🎉 PRUEBAS COMPLETADAS CON ÉXITO" -ForegroundColor Green
            Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Green
        } else {
            Write-ErrorMsg "Algunas pruebas fallaron"
            Write-Host ""
            Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
            Write-Host "  ⚠️  REVISAR ERRORES ARRIBA" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-InfoMsg "Para más información, consulta: PRUEBA_CRM_OPERACIONES.md"
        Write-Host ""
        
        exit $exitCode
        
    } catch {
        Write-ErrorMsg "Error al ejecutar las pruebas: $_"
        exit 1
    }
}

# Ejecutar
Main
