import time
import os
import requests
import urllib.request
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.edge.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


daftar_gambar = meja_kerja_items = [
    "Monitor",
    "Keyboard",
    "Mouse",
    "Mousepad",
    "Notebook",
    "Buku Catatan",
    "Pulpen",
    'tempat alat tulis',
    "Pensil",
    "Telepon",
    "Smartphone",
    "Charger",
    "Lampu Meja",
    "Headset",
    "Earphone",
    "Dokumen",
    "Berkas",
    "Organizer",
    "Rak Penyimpanan",
    "Botol Air",
    "Gelas",
    "Tanaman Hias Kecil",
    "Kalender",
    "Jam",
    "Kabel",
    "Adaptor",
    "Sticky Notes",
    "Gunting",
    "Staples",
    "Keyboard Tray",
    "Makanan Ringan"
]

for item in daftar_gambar:
    folder_name = f'images\\{item}'
    if not os.path.isdir(folder_name):
        os.makedirs(folder_name)

def download_image(url, folder_name, num):
    response = requests.get(url)
    if response.status_code == 200:
        with open(os.path.join(folder_name, str(num) + "_.jpg"), 'wb') as file:
            file.write(response.content)

def download_image_2(url, folder_name, num):
    response = urllib.request.urlopen(url)
    data = response.read()

    with open(os.path.join(folder_name, str(num) + "_.jpg"), 'wb') as file:
        file.write(data)

chromeDriverPath = r"D:\Utils\compfest-scrapping\chromedriver-win64\chromedriver.exe"

options = webdriver.ChromeOptions()
service = Service(executable_path=chromeDriverPath)
driver = webdriver.Chrome(service=service, options=options)

base_url = 'https://www.google.com/search?q='

for item in daftar_gambar:

    folder_name = f'images\\{item}'

    keyword = "+" + "+".join(item.split(" "))

    driver.get(f"https://www.google.com/search?q={keyword}&tbm=isch")

    page_html = driver.page_source
    page_soup = BeautifulSoup(page_html, "html.parser")

    div_container = page_soup.find_all("div", {"class": "eA0Zlc WghbWd FnEtTd mkpRId m3LIae RLdvSe qyKxnc ivg-i PZPZlf GMCzAd"})

    jumlah_data = len(div_container)

    for i in range(1, jumlah_data + 1):
        try:
            if i % 25 == 0:
                break

            xPath = f"""//*[@id="rso"]/div/div/div[1]/div/div/div[{i}]"""

            previewImageXPath = f"""//*[@id="rso"]/div/div/div[1]/div/div/div[{i}]/div[2]/h3/a/div/div/div/g-img/img"""
            previewImageElement = driver.find_element(By.XPATH, previewImageXPath)
            previewImageURL = previewImageElement.get_attribute("src")

            driver.find_element(By.XPATH, xPath).click()

            time.sleep(10)

            imageElement = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.XPATH, """//*[@id="Sva75c"]/div[2]/div[2]/div/div[2]/c-wiz/div/div[3]/div[1]/a/img[1]"""))
            )
            imageURL = imageElement.get_attribute('src')

            try:
                download_image_2(imageURL, folder_name, i)
                print(f"Berhasil-foto-{i}")
            except Exception as e:
                print(f"Gagal-foto-{i}, error: {e}")

        except Exception as e:
            print(f"Gagal-foto-{i}, error: {e}")

driver.quit()
