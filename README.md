# ARP_Spoof_Automatic

> 🛡️ Script educativo para demostrar un ataque de ARP Spoofing que causa un DoS local. Creado para aprender a auditar y proteger tu propia red. ⚠️ **USO ÉTICO EXCLUSIVAMENTE**. Es ilegal usarlo en redes ajenas sin permiso explícito. ¡Actúa con responsabilidad!

---

## 🛡️ Herramienta Educativa de ARP Spoofing y DoS Local 🛡️

Esta es una descripción para el script `DDoS_ArpSpoof.sh`, diseñado para entornos de aprendizaje y pruebas de seguridad controladas.

## ⚠️ Descargo de Responsabilidad (Disclaimer) ⚠️

**¡MUY IMPORTANTE!** El uso de esta herramienta en redes o sistemas sobre los que no tienes permiso explícito y por escrito es **ilegal** y está terminantemente prohibido. Realizar ataques informáticos sin autorización puede acarrear graves consecuencias legales.

El autor de este script lo proporciona con fines educativos y no se hace responsable del mal uso que se le pueda dar. Úsala bajo tu propia responsabilidad y siempre dentro de la legalidad.

## 🎓 Propósito Definido 🎓

El objetivo principal de esta herramienta es **educativo y de investigación**. Ha sido creada para que administradores de red, estudiantes y profesionales de la ciberseguridad puedan:

- Comprender de forma práctica cómo funciona un ataque de envenenamiento de caché ARP (ARP Spoofing).
- Probar la seguridad de sus propias redes (*pentesting* ético) para identificar si son vulnerables a este tipo de ataques.
- Aprender a desarrollar contramedidas para detectar y mitigar estas amenazas en un entorno de laboratorio controlado.

## 💻 Descripción Técnica Neutra 💻

El script `DDoS_ArpSpoof.sh` automatiza el proceso de un ataque de suplantación de identidad en una red local. Técnicamente, realiza las siguientes acciones:

**1. Envenenamiento de Caché ARP (ARP Spoofing):** La herramienta utiliza `arpspoof` para enviar paquetes ARP falsificados a dos puntos de la red:
    - Le dice al dispositivo "víctima" que la dirección MAC del router (gateway) pertenece ahora al equipo del atacante.
    - Le dice al router que la dirección MAC del dispositivo "víctima" pertenece ahora al equipo del atacante.

**2. Denegación de Servicio (DoS):** A diferencia de un ataque *Man-in-the-Middle* (MitM) donde el tráfico se intercepta y reenvía, este script desactiva deliberadamente el reenvío de paquetes en el equipo atacante (`net.ipv4.ip_forward=0`). Como resultado, todo el tráfico de la víctima que intenta salir a Internet es redirigido al equipo atacante, donde es descartado. Esto provoca una interrupción total de la conexión para la víctima, resultando en una Denegación de Servicio efectiva a nivel local.

El script cuenta con una interfaz amigable, autocomprobación de privilegios y dependencias, y una función de limpieza segura (`Ctrl+C`) que detiene el ataque y restaura la tabla ARP de los dispositivos afectados para no dejar la red inoperativa.

## ✅ Mención del Uso Responsable ✅

Se insiste en la necesidad de utilizar esta utilidad de manera **ética y completamente responsable**.

- **NUNCA** la ejecutes contra redes públicas, corporativas o privadas ajenas.
- **SIEMPRE** obtén permiso explícito antes de realizar cualquier prueba de seguridad, incluso en redes de amigos o familiares.
- **UTILÍZALA** preferiblemente en un entorno de laboratorio aislado y controlado, con máquinas virtuales propias, para evitar cualquier impacto no deseado.

El hacking ético se fundamenta en el permiso, la ética y el objetivo de mejorar la seguridad, no de comprometerla. 🤝
