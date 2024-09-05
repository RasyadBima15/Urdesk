import functions_framework
import io
import json
import torch
import tensorflow as tf
import os
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

from ultralytics import YOLO
from flask import jsonify, request
from google.cloud import storage
from PIL import Image, ImageDraw

storage_client = storage.Client()

REPORT = {"error":"no-error", "predictions":[]}
message = ["Workspace is tidy", "Workspace is messy", "Trash detected", "No trash detected", "Anomaly detected", "No anomaly detected", "Object detected", "No object detected"]

BUCKET_NAME = "urdesk-data"
MODEL_CLASSIFICATION = "models/best_model_NasnetLarge.h5"
MODEL_ANOMALI_DETECTION = "models/best-anomaly-detection.pt"
MODEL_TRASH_DETECTION = "models/model-5-trash-detection.pt"
MODEL_OBJECT_DETECTION = "models/best_object_detection_model.pt"

def download_image(file_path):
    try:
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(file_path)
        image_data = blob.download_as_bytes()
        return Image.open(io.BytesIO(image_data))
    except Exception as e:
        REPORT['error'] = f"Error downloading image {file_path}: {e}"
        raise

def upload_results_to_bucket(bucket_name, destination_path, data):
    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_path)
        blob.upload_from_string(json.dumps(data), content_type='application/json')
    except Exception as e:
        REPORT['error'] = f"Error uploading results to bucket {destination_path}: {e}"
        raise

def download_model_from_gcs(model_path, destination_path):
    try:
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(model_path)
        blob.download_to_filename(destination_path)
    except Exception as e:
        REPORT['error'] = f"Error downloading model {model_path}: {e}"
        raise

def create_heatmap(image_path, results, folder_name):
    try:
        image = Image.open(image_path)
        width, height = image.size
        heatmap = np.zeros((height, width))

        for result in results.pandas().xyxy[0].itertuples():
            x_min, y_min, x_max, y_max = result.xmin, result.ymin, result.xmax, result.ymax
            heatmap[int(y_min):int(y_max), int(x_min):int(x_max)] += 1

        heatmap = np.clip(heatmap / np.max(heatmap), 0, 1)

        plt.figure(figsize=(width / 100, height / 100), dpi=100)
        plt.imshow(heatmap, cmap='jet', alpha=0.5)
        plt.axis('off')

        heatmap_image_path = "/tmp/heatmap.png"
        plt.savefig(heatmap_image_path, bbox_inches='tight', pad_inches=0)
        plt.close()

        heatmap_image = Image.open(heatmap_image_path).convert("RGBA")
        image = image.convert("RGBA")

        combined = Image.blend(image, heatmap_image, alpha=0.5)

        combined_image_path = "/tmp/combined_image.jpg"
        combined.save(combined_image_path)

        upload_image_to_bucket(BUCKET_NAME, folder_name, combined_image_path)

        os.remove(heatmap_image_path)
        os.remove(combined_image_path)
    except Exception as e:
        REPORT['error'] = f"Error creating heatmap: {e}"
        raise

def upload_image_to_bucket(bucket_name, folder_name, local_image_path):
    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)

        file_name = os.path.basename(local_image_path)
        destination_blob_name = f'images/{folder_name}/predict/{file_name}'

        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(local_image_path)
    except Exception as e:
        REPORT['error'] = f"Error uploading image {local_image_path} to bucket: {e}"
        raise

def preprocess_image(image_path):
    try:
        image = Image.open(image_path)
        image = image.resize((224, 224))
        image_array = np.array(image) / 255.0
        image_array = np.expand_dims(image_array, axis=0)
        return image_array
    except Exception as e:
        REPORT['error'] = f"Error preprocessing image {image_path}: {e}"
        raise

def add_Message(poin, message, list_detection, image_url=None):
    REPORT['predictions'].append(
        {
            "poin": poin,
            "message": message,
            "imageURL": image_url,
            "list_detection": list_detection,
        }
    )

def process_images(model_path, file_name, folder_name, n):
    try:
        if not os.path.exists(model_path):
            download_model_from_gcs(model_path.split('/')[-1], model_path)

        image_1 = f'/tmp/images/{file_name}_front.jpg'
        image_2 = f'/tmp/images/{file_name}_top.jpg'

        model = YOLO(model_path)

        results_1 = model(image_1)
        results_2 = model(image_2)

        detection = set()

        for result in results_1:
            for class_name in result.names:
                detection.add(result.names[class_name])

        for result in results_2:
            for class_name in result.names:
                detection.add(result.names[class_name])

        detection = list(detection)

        output_image_1 = f'/tmp/{file_name}_front_bounded.jpg'
        output_image_2 = f'/tmp/{file_name}_top_bounded.jpg'

        results_1.save(output_image_1)
        results_2.save(output_image_2)

        if n != 3:
            upload_image_to_bucket(BUCKET_NAME, folder_name, output_image_1)
            upload_image_to_bucket(BUCKET_NAME, folder_name, output_image_2)
        else:
            create_heatmap(image_1, results_1, folder_name)

        return detection
    except Exception as e:
        REPORT['error'] = f"Error processing images: {e}"
        raise

def classfication_predict(file_name):
    try:
        model_path = f"/tmp/models/{MODEL_CLASSIFICATION}"

        if not os.path.exists(model_path):
            download_model_from_gcs(MODEL_CLASSIFICATION, model_path)

        model = tf.keras.models.load_model(model_path)

        image_path = f'/tmp/images/{file_name}_front.jpg'
        processed_image = preprocess_image(image_path)

        predictions = model.predict(processed_image)

        predicted_class = np.argmax(predictions, axis=1)
        class_names = ['messy', 'tidy']

        if predicted_class == 0:
            add_Message(0, message[1], class_names[predicted_class], None)
        else:
            add_Message(1, message[0], class_names[predicted_class], None)
    except Exception as e:
        REPORT['error'] = f"Error in classification: {e}"
        raise

def anomali_detection(file_name):
    try:
        model_path = f"/tmp/models/{MODEL_ANOMALI_DETECTION}"
        folder_name = f'{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, 1)

        image_url = [f"{folder_name}/{1}_{file_name}_front_bounded.jpg", f"{folder_name}/{1}_{file_name}_top_bounded.jpg"]

        if detection:
            add_Message(0, message[5], detection, image_url)
        else:
            add_Message(1, message[4], detection, image_url)
    except Exception as e:
        REPORT['error'] = f"Error in anomaly detection: {e}"
        raise

def trash_detection(file_name):
    try:
        model_path = f"/tmp/models/{MODEL_TRASH_DETECTION}"
        folder_name = f'images/{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, 2)

        image_url = [f"{folder_name}/{2}_{file_name}_front_bounded.jpg", f"{folder_name}/{2}_{file_name}_top_bounded.jpg"]

        if detection:
            add_Message(0, message[3], detection, image_url)
        else:
            add_Message(1, message[2], detection, image_url)
    except Exception as e:
        REPORT['error'] = f"Error in trash detection: {e}"
        raise

def object_detection(file_name):
    try:
        model_path = f"/tmp/models/{MODEL_OBJECT_DETECTION}"
        folder_name = f'images/{file_name}/predictions'
        detection = process_images(model_path, file_name, folder_name, 3)

        image_url = [f"{folder_name}/combined_image.jpg"]

        if detection:
            add_Message(0, message[7], detection, image_url)
        else:
            add_Message(1, message[6], detection, image_url)
    except Exception as e:
        REPORT['error'] = f"Error in object detection: {e}"
        raise

def upload_results_to_bucket(bucket_name, file_name, report):
    try:
        bucket = storage_client.bucket(bucket_name)
        folder_name = f'images/{file_name}/predictions'
        report_file_name = f'{folder_name}/report.json'

        blob = bucket.blob(report_file_name)
        blob.upload_from_string(json.dumps(report), content_type='application/json')

        print(f"Report successfully uploaded to {report_file_name}")
    except Exception as e:
        REPORT['error'] = f"Error uploading report to {report_file_name}: {e}"
        raise

@functions_framework.http
def predict_image(request):
    try:
        file_name = request.args.get('file_name')

        classfication_predict(file_name)
        anomali_detection(file_name)
        trash_detection(file_name)
        object_detection(file_name)

        upload_results_to_bucket(BUCKET_NAME, file_name, REPORT)

        return jsonify(REPORT)

    except Exception as e:
        return jsonify({"error": f"General error: {e}"})

