# ReciclApp

Cuenta botellas, las guarda en un inventario de este navegador y busca basureros cerca. Las fotos no salen del dispositivo.

| | |
|---|---|
| Materia | Soporte a la toma de decisiones |
| Docente | Jesús Bautista |
| Alumno | Luishiño Pericena |

Hay dos formas de usarlo:

- **Página de juego** (`web/`): cámara, foto o video, inventario y mapa. No usa Flask.
- **Flask** (`python app.py`): webcam con cajas de `botella.xml` y el mismo mapa.

## Página de juego

Desde la raíz del proyecto:

```bash
python -m http.server 8765 --directory web
```

Abre http://127.0.0.1:8765 . Si el puerto está ocupado, cambia el número. No abras `index.html` con doble clic: la cámara y el mapa necesitan `http://`.

**Jugar** es el tablero. **Mapa** son los basureros. El número de arriba es el total guardado.

1. **Cámara** cuenta sola. **Foto** acepta JPG, PNG, WEBP o GIF, hasta 12 MB. **Video** acepta MP4, WEBM o QuickTime.
2. Si hay dos botellas distintas, entran las dos. La misma no se vuelve a guardar mientras siga a la vista.
3. **Registrar ahora** fuerza el registro. **Nueva toma** permite contar otra vez las de esta toma.
4. En la imagen se dibujan las cajas. Por debajo del 60 % el resultado se marca como poco seguro.

Solo cuenta la clase `bottle` (COCO-SSD, al menos 0,50). Si están los pesos en `web/modelo_botellas/`, la red propia confirma el recorte: por encima de 0,50 es botella.

El inventario queda en el navegador (`botellas-ia-inventario-v1`). Cada fila tiene fecha, cantidad editable, confianza y cajas, con etiqueta `Botella`. Se puede borrar una fila, vaciar todo, o descargar JSON y CSV.

En el mapa, **Mi ubicación** o una ciudad buscan en 1200 m. Amarillo es basurero, verde es contenedor y azul es punto de reciclaje. Esa búsqueda sí usa internet. Las fotos no se envían.

## Flask

```bash
python -m pip install flask flask-sock opencv-python==4.11.0.86
python app.py
```

Abre http://127.0.0.1:5000 . Hace falta OpenCV 4: la versión 5 no trae `CascadeClassifier`. La webcam se abre al pedir `/video_feed`, no al arrancar. Si la página de juego ya usa la cámara, ciérrala antes.

`botella.xml` marca las cajas (ventana 38×46, `scaleFactor=1.3`, `minNeighbors=8`). El mapa está en la misma página, con `static/js/mapa.js`.

## Volver a entrenar los pesos

Los archivos que carga la página son:

- `web/modelo_botellas/model.json`
- `web/modelo_botellas/group1-shard1of2.bin`
- `web/modelo_botellas/group1-shard2of2.bin`

La red es gris, 100×100: tres convoluciones (32, 64 y 128) con MaxPool, luego dos capas densas. La última es una sigmoide.

Clase botella: las fotos de [bottle-detection-dataset](https://www.kaggle.com/datasets/diptosen/bottle-detection-dataset/data) (`bottles_closeups` y `bottles_occluded`) más `img/p`, `dato/p` y `dato/img/p2`. Ese dataset no trae “no botella”. Los fondos son `img/n`, `dato/n` y `dato/img/n2`.

Con el dataset ya descargado por kagglehub y TensorFlow instalado:

```bash
py -3 -u entrenamiento/exportar_bins.py
```

El script escribe otra vez los dos `.bin`. Esos nombres no se cambian: la página los busca así.

`clasificador/botellas.ipynb` no entrena esa red. Muestra las cajas de `botella.xml` sobre `video_feed/bottles.mp4`.

## Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| `No module named cv2` | Instala OpenCV con el mismo `python` que ejecuta `app.py` |
| No existe `CascadeClassifier` | Ese Python tiene OpenCV 5. Instala `opencv-python==4.11.0.86` |
| La cámara no arranca | Otro programa la tiene abierta |
| Cuenta botellas pero no usa la red propia | Faltan los `.bin`, o la página no se abrió con `http://` |
| El mapa no encuentra el lugar | Reintenta: hace falta internet |
| Se ve el diseño viejo | Borra la caché del sitio |
