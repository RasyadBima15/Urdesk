import functions_framework
import io
import json
import torch
import tensorflow as tf
import cv2
import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import shutil

from ultralytics import YOLO
from flask import jsonify, request
from google.cloud import storage
from PIL import Image, ImageDraw

storage_client = storage.Client(project='urdesk')

REPORT = {"error": "no-error", "predictions": []}
message = [
    "Selamat! Meja kerja Anda terlihat sangat rapi dan terorganisir. Menjaga meja yang tertata seperti ini membantu Anda tetap fokus dan meningkatkan produktivitas. Terus pertahankan kebiasaan ini untuk mendukung pertumbuhan bakat dan kemajuan karier Anda!",
    "Meja Anda terdeteksi berantakan, mungkin ini saat yang tepat untuk merapikannya. Lingkungan kerja yang kotor dapat mengganggu konsentrasi dan menurunkan efisiensi. Dengan merapikan meja, Anda bisa menciptakan suasana yang lebih mendukung untuk berkembang dan mempercepat pertumbuhan bakat Anda.",
    "Bagus sekali! Meja Anda bersih dan bebas dari sampah. Lingkungan kerja yang bersih membantu menjaga konsentrasi dan membuat suasana kerja lebih nyaman. Terus jaga kebersihan ini agar mendukung produktivitas dan pertumbuhan bakat Anda!",
    "Meja Anda terdeteksi memiliki sampah, mungkin ini saat yang tepat untuk membersihkannya. Sampah seperti kertas atau sisa makanan bisa mengganggu kenyamanan dan menurunkan motivasi kerja. Dengan membuang sampah, Anda bisa menciptakan lingkungan yang lebih mendukung untuk produktivitas dan pengembangan bakat.",
    "Meja Anda tampak teratur dan bebas dari tumpukan barang yang berantakan. Dengan lingkungan yang rapi, Anda menciptakan ruang kerja yang nyaman dan efisien. Tetap jaga kerapian ini untuk mendukung kreativitas dan pertumbuhan bakat Anda secara optimal!",
    "Terlihat ada tumpukan barang yang tidak teratur di meja Anda, seperti buku atau alat tulis yang berserakan. Lingkungan kerja yang berantakan bisa menghambat fokus dan mengurangi produktivitas. Dengan merapikan barang-barang ini, Anda bisa menciptakan suasana yang lebih kondusif untuk berkembang dan mencapai potensi maksimal Anda.",
    "Sepertinya saya tidak mendeteksi barang-barang penting untuk pekerjaan di atas meja Anda, yang berarti meja Anda tampak kosong atau tidak dipenuhi oleh hal-hal yang mendukung produktivitas. Jika ada barang yang tidak diperlukan, pertimbangkan untuk menyingkirkannya agar tidak mengganggu konsentrasi Anda. Meja Anda sudah ideal dengan jumlah barang yang pas—cukup untuk mendukung pekerjaan tanpa membuat sesak. Ruang kerja yang tertata rapi dan tidak terlalu penuh akan membantu pergerakan Anda lebih leluasa, meningkatkan fokus, dan mendukung efisiensi. Pertahankan keseimbangan ini agar produktivitas tetap terjaga dan perkembangan Anda semakin optimal!",
    "Saya telah menandai barang-barang yang penting dan mendukung produktivitas Anda—sisanya, saya sarankan untuk disingkirkan. Meja yang terlalu penuh bisa membuat ruang terasa sempit dan membatasi fleksibilitas Anda saat bekerja. Cobalah mengurangi jumlah barang di meja agar lingkungan kerja terasa lebih nyaman dan mendukung produktivitas, sehingga Anda bisa lebih fokus dan terus mengembangkan potensi diri!"
]

BUCKET_NAME = "urdesk-data"
MODEL_CLASSIFICATION = "models/best_model_NasnetLarge.h5"
MODEL_ANOMALY_DETECTION = "models/best-anomaly-detection.pt"
MODEL_TRASH_DETECTION = "models/model-5-trash-detection.pt"
MODEL_OBJECT_DETECTION = "models/best_object_detection_model.pt"

def download_image(code, file_name):
    file_path = f"images/{code}/{file_name}"
    print(f"Downloading image from {file_path}")
    try:

        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(file_path)
        image_data = blob.download_as_bytes()

        image_dir = '/tmp/urdesk/images'
        if not os.path.exists(image_dir):
            os.makedirs(image_dir)

        image_path = f"{image_dir}/{file_name}"
        with open(image_path, 'wb') as f:
            f.write(image_data)

        print(f"Image successfully downloaded to {image_path}")
        return image_path
    except Exception as e:
        REPORT['error'] = f"Error downloading image {file_path}: {e}"
        print(REPORT['error'])
        raise

def upload_results_to_bucket(bucket_name, destination_path, data):
    print(f"Uploading results to bucket {destination_path}")
    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_path)
        blob.upload_from_string(json.dumps(data), content_type='application/json')
        print(f"Results successfully uploaded to {destination_path}")
    except Exception as e:
        REPORT['error'] = f"Error uploading results to bucket {destination_path}: {e}"
        print(REPORT['error'])
        raise

def download_model_from_gcs(model_path, destination_path):
    print(f"Downloading model from {model_path} to {destination_path}")
    try:
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(model_path)

        model_dir = os.path.dirname(destination_path)
        if not os.path.exists(model_dir):
            os.makedirs(model_dir)

        blob.download_to_filename(destination_path)

        if os.path.exists(destination_path):
            print(f"Model successfully downloaded to {destination_path}")
        else:
            print(f"Model download failed for {destination_path}")

    except Exception as e:
        REPORT['error'] = f"Error downloading model {model_path}: {e}"
        print(REPORT['error'])
        raise

def create_heatmap(image_path, results, folder_name):
    try:
        image = Image.open(image_path)
        width, height = image.size
        heatmap = np.zeros((height, width))

        for result in results:
            boxes = result.boxes.xyxy.cpu().numpy()
            for box in boxes:
                x_min, y_min, x_max, y_max = box[:4]
                x_min, y_min = max(0, int(x_min)), max(0, int(y_min))
                x_max, y_max = min(width, int(x_max)), min(height, int(y_max))
                heatmap[y_min:y_max, x_min:x_max] += 1

        heatmap = np.clip(heatmap / np.max(heatmap), 0, 1)

        plt.figure(figsize=(width / 100, height / 100), dpi=100)
        plt.imshow(heatmap, cmap='jet', alpha=0.5)
        plt.axis('off')

        heatmap_image_path = "/tmp/urdesk/heatmap.png"
        plt.savefig(heatmap_image_path, bbox_inches='tight', pad_inches=0)
        plt.close()

        heatmap_image = Image.open(heatmap_image_path).convert("RGBA")
        image = image.convert("RGBA")

        combined = Image.blend(image, heatmap_image, alpha=0.5)

        combined_image_path = "/tmp/urdesk/combined_image.jpg"
        combined.save(combined_image_path)

        upload_image_to_bucket(BUCKET_NAME, folder_name, combined_image_path)

        os.remove(heatmap_image_path)
        os.remove(combined_image_path)

    except Exception as e:
        REPORT['error'] = f"Error creating heatmap: {e}"
        print(REPORT['error'])
        raise


def upload_image_to_bucket(bucket_name, folder_name, local_image_path):
    print(f"Uploading image {local_image_path} to bucket {bucket_name}")
    try:

        client = storage.Client()
        bucket = client.bucket(bucket_name)

        file_name = os.path.basename(local_image_path)
        destination_blob_name = f'{folder_name}/{file_name}'

        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(local_image_path)

        print(f"Image successfully uploaded to {destination_blob_name}")
    except Exception as e:
        REPORT['error'] = f"Error uploading image {local_image_path} to bucket: {e}"
        print(REPORT['error'])
        raise


def preprocess_image(image_path):
    print(f"Preprocessing image {image_path}")
    try:

        image = Image.open(image_path)

        image = image.resize((224, 224))

        image_array = np.array(image) / 255.0

        if image_array.ndim == 2:
            image_array = np.stack([image_array] * 3, axis=-1)

        image_array = np.expand_dims(image_array, axis=0)

        return image_array
    except Exception as e:
        REPORT['error'] = f"Error preprocessing image {image_path}: {e}"
        print(REPORT['error'])
        raise


def add_Message(poin, message, list_detection, image_url=None):
    print(f"Adding message to report: point={poin}, message={message}")
    REPORT['predictions'].append(
        {
            "poin": poin,
            "message": message,
            "imageURL": image_url,
            "list_detection": list_detection,
        }
    )


def process_images(model_path, file_name, folder_name, n, confidence_level=0.3):
    try:
        if not os.path.exists(model_path):
            download_model_from_gcs(model_path.split('/')[-1], model_path)

        image_1 = f'/tmp/urdesk/images/{file_name}_front.jpg'
        image_2 = f'/tmp/urdesk/images/{file_name}_top.jpg'

        model = YOLO(model_path)

        results_1 = model(image_1, conf=confidence_level)
        results_2 = model(image_2, conf=confidence_level)

        detection = set()
        for result in results_1:
            if result.names:
                detected_classes = [result.names[int(label)] for label in result.boxes.cls.cpu().numpy()]
                detection.update(detected_classes)

        for result in results_2:
            if result.names:
                detected_classes = [result.names[int(label)] for label in result.boxes.cls.cpu().numpy()]
                detection.update(detected_classes)

        detection = list(detection)

        output_image_1 = f'/tmp/urdesk/{n}_{file_name}_front_bounded.jpg'
        output_image_2 = f'/tmp/urdesk/{n}_{file_name}_top_bounded.jpg'

        for result in results_1:
            result.save(output_image_1)

        for result in results_2:
            result.save(output_image_2)

        upload_image_to_bucket(BUCKET_NAME, folder_name, output_image_1)
        upload_image_to_bucket(BUCKET_NAME, folder_name, output_image_2)

        return detection
    except Exception as e:
        REPORT['error'] = f"Error processing images: {e}"
        raise

def classfication_predict(file_name):
    print(f"Running classification prediction for file {file_name}")
    try:
        model_path = f"/tmp/urdesk/{MODEL_CLASSIFICATION}"

        if not os.path.exists(model_path):
            download_model_from_gcs(MODEL_CLASSIFICATION, model_path)

        model = tf.keras.models.load_model(model_path)

        image_path = f'/tmp/urdesk/images/{file_name}_front.jpg'
        processed_image = preprocess_image(image_path)

        predictions = model.predict(processed_image)

        predicted_class = np.argmax(predictions, axis=1)[0]
        class_names = ['messy', 'tidy']

        if predicted_class == 0:
            add_Message(0, message[1], class_names[predicted_class], None)
        else:
            add_Message(1, message[0], class_names[predicted_class], None)

        print(f"Classification prediction completed: {class_names[predicted_class]}")

    except Exception as e:
        REPORT['error'] = f"Error in classification: {e}"
        print(REPORT['error'])
        raise

def anomaly_detection(file_name):
    print(f"Running anomaly detection for file {file_name}")
    try:
        model_path = f"/tmp/urdesk/{MODEL_ANOMALY_DETECTION}"

        if not os.path.exists(model_path):
            download_model_from_gcs(MODEL_ANOMALY_DETECTION, model_path)

        folder_name = f'images/{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, "anomaly")

        image_url = [f"{folder_name}/anomaly_{file_name}_front_bounded.jpg", f"{folder_name}/anomaly_{file_name}_top_bounded.jpg"]

        if detection:
            add_Message(0, message[5], detection, image_url)
        else:
            add_Message(1, message[4], detection, image_url)

        print(f"Anomaly detection completed: {detection}")
    except Exception as e:
        REPORT['error'] = f"Error in anomaly detection: {e}"
        print(REPORT['error'])
        raise

def trash_detection(file_name):
    print(f"Running trash detection for file {file_name}")
    try:

        model_path = f"/tmp/urdesk/{MODEL_TRASH_DETECTION}"

        if not os.path.exists(model_path):
            download_model_from_gcs(MODEL_TRASH_DETECTION, model_path)

        folder_name = f'images/{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, "trash", 0.4)

        image_url = [f"{folder_name}/trash_{file_name}_front_bounded.jpg", f"{folder_name}/trash_{file_name}_top_bounded.jpg"]

        if detection:
            add_Message(0, message[3], detection, image_url)
        else:
            add_Message(1, message[2], detection, image_url)

        print(f"Trash detection completed: {detection}")
    except Exception as e:
        REPORT['error'] = f"Error in trash detection: {e}"
        print(REPORT['error'])
        raise

def object_detection(file_name):
    print(f"Running object detection for file {file_name}")
    try:

        model_path = f"/tmp/urdesk/{MODEL_OBJECT_DETECTION}"

        if not os.path.exists(model_path):
            download_model_from_gcs(MODEL_OBJECT_DETECTION, model_path)

        folder_name = f'images/{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, "object")

        image_url = [f"{folder_name}/object_{file_name}_front_bounded.jpg", f"{folder_name}/object_{file_name}_top_bounded.jpg"]

        if detection:
            add_Message(0, message[7], detection, image_url)
        else:
            add_Message(1, message[6], detection, image_url)

        print(f"Object detection completed: {detection}")
    except Exception as e:
        REPORT['error'] = f"Error in object detection: {e}"
        print(REPORT['error'])
        raise

def upload_results_to_bucket(bucket_name, file_name, report):
    print(f"Uploading report to bucket for file {file_name}")
    try:

        bucket = storage_client.bucket(bucket_name)
        folder_name = f'images/{file_name}/predictions'
        report_file_name = f'{folder_name}/report.json'

        blob = bucket.blob(report_file_name)
        blob.upload_from_string(json.dumps(report), content_type='application/json')

        print(f"Report successfully uploaded to {report_file_name}")
    except Exception as e:
        REPORT['error'] = f"Error uploading report to {report_file_name}: {e}"
        print(REPORT['error'])
        raise

def cleanup_tmp_directory():
    tmp_dir = '/tmp/urdesk'
    try:
        for item in os.listdir(tmp_dir):
            item_path = os.path.join(tmp_dir, item)
            if os.path.isdir(item_path) and item != 'models':
                shutil.rmtree(item_path)
            elif os.path.isfile(item_path):
                os.remove(item_path)
    except Exception as e:
        REPORT['error'] = f"Error cleaning up tmp directory: {e}"
        print(REPORT['error'])
        raise


def create_directory():
    directory_path = '/tmp/urdesk'

    if not os.path.exists(directory_path):
        os.makedirs(directory_path)

    return directory_path

@functions_framework.http
def predict_image(request):
    try:
        print("Received request")
        request_json = request.get_json()

        if not request_json or 'file_name' not in request_json:
            return jsonify({"error": "No file_name parameter provided in the request body"}), 400

        create_directory()

        file_name = request_json['file_name']
        print(f"Processing file_name: {file_name}")

        cleanup_tmp_directory()

        image_1 = download_image(f'{file_name}', f'{file_name}_front.jpg')
        image_2 = download_image(f'{file_name}', f'{file_name}_top.jpg')

        classfication_predict(file_name)
        object_detection(file_name)
        anomaly_detection(file_name)
        trash_detection(file_name)

        upload_results_to_bucket(BUCKET_NAME, file_name, REPORT)

        print("Processing completed")
        return jsonify(REPORT)

    except Exception as e:
        print(f"General error: {e}")
        return jsonify({"error": f"General error: {e}"}), 500
