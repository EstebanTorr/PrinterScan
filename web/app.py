from flask import Flask
from flask import render_template
from flask import send_from_directory
from flask_sock import Sock
from flask import Response
import sys
import time
import cv2



app = Flask(__name__)
sock = Sock(app)
# No abrir la webcam al importar: en Windows queda exclusiva y el navegador
# responde "Could not start video source". Se abre al pedir /video_feed.
cap = None

def obtener_camara():
    global cap
    if cap is None or not cap.isOpened():
        # CAP_DSHOW solo existe en Windows. En Docker (Linux) se usa el backend normal.
        backend = cv2.CAP_DSHOW if sys.platform == "win32" else cv2.CAP_ANY
        cap = cv2.VideoCapture(0, backend)
    return cap
# reciclap = cv2.CascadeClassifier(cv2.data.haarcascades +
#     "haarcascade_eye.xml")


reciclap = cv2.CascadeClassifier('botella.xml')


def generate():
    camara = obtener_camara()
    while True:
        ret, frame = camara.read() if camara.isOpened() else (False, None)
        if not ret:
            time.sleep(0.3)
            continue
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        # Ventana del cascade: 38x46. scaleFactor=5 y minNeighbors=91
        # dejaban la imagen casi sin cajas.
        cajas = reciclap.detectMultiScale(gray,
                                        scaleFactor=1.3,
                                        minNeighbors=8,
                                        minSize=(38, 46))
        for (x, y, w, h) in cajas:
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
            cv2.putText(frame, 'botella', (x, y-10),
                        2, 0.7, (0, 255, 0), 2, cv2.LINE_AA)

        flag, encodedImage = cv2.imencode(".jpg", frame)
        if not flag:
            continue
        yield(b'--frame\r\n' b'Content-Type: image/jpeg\r\n\r\n' +
              bytearray(encodedImage) + b'\r\n')


@app.route("/")
def index():
    return render_template("index.html", titulo="ReciclApp")


@app.route("/juego/")
@app.route("/juego/<path:nombre>")
def juego(nombre="index.html"):
    return send_from_directory("web", nombre)

@sock.route('/echo')
def echo(sock):
    while True:
        data = sock.receive()
        sock.send(data)


@app.route("/video_feed")
def video_feed():
    return Response(generate(),
                    mimetype="multipart/x-mixed-replace; boundary=frame")


@app.route('/perfil', methods=['GET', 'POST'])  # ['GET', 'POST']
def perfil():
    titulo = "Reciclapp"
    return render_template('perfil/index.html',
                           titulo=titulo,)


@app.route('/map', methods=['GET', 'POST'])  # ['GET', 'POST']
def map():
    titulo = "Reciclapp"
    return render_template('map/index.html',
                           titulo=titulo,)


# if __name__ == "__main__":
#    app.run(debug=False)
if __name__ == '__main__':
    app.run(host='0.0.0.0')
if cap is not None:
    cap.release()
# cap.release()
