# Reverb por Convolución

Aplicación interactiva desarrollada en **MATLAB** para simular el efecto de reverberación acústica en archivos de audio (`.wav`). 

El proyecto permite tomar una grabación limpia (seca) y aplicarle las características acústicas de un espacio real —como una sala, una iglesia o un estudio— mediante el procesamiento de una **Respuesta al Impulso (IR)**.

## ¿Qué hace esta aplicación?

* **Carga de audios:** Permite seleccionar cualquier pista de audio limpia y combinarla con el archivo de respuesta al impulso de un entorno acústico.
* **Visualización gráfica:** Muestra en pantalla la comparación visual entre la onda del audio original y la señal resultante con el efecto aplicado.
* **Control de mezcla en tiempo real:** Incluye un deslizador interactivo para ajustar el porcentaje de reverberación deseado (de 0% a 100%) mientras se escucha el resultado.
* **Controles de reproducción:** Cuenta con opciones directas para reproducir, pausar y reiniciar la pista desde el inicio.

## Requisitos para ejecutarlo

* **MATLAB** (versión de escritorio).
* **Audio Toolbox** (necesario para la reproducción de audio en tiempo real).
* Dos archivos en formato `.wav` (uno con el audio base y otro con el impulso acústico).

