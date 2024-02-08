import os 
from pydrive.auth import GoogleAuth 
from pydrive.drive import GoogleDrive
import zipfile
import datetime

gauth = GoogleAuth()
gauth.LocalWebserverAuth()
drive = GoogleDrive(gauth)

OUTPUT_FILE_NAME = f"results_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.zip"
GDRIVE_FOLDER_ID = os.environ['GDRIVE_FOLDER_ID']

def zipdir(files, out):
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file in files:
            zipf.write(file)

def upload_file_to_drive(file, folder_id):
    file_drive = drive.CreateFile({'parents': [{'id': folder_id}]})
    file_drive.SetContentFile(file)
    file_drive.Upload()

files_to_zip = [os.path.join('results', file) for file in os.listdir('results')]
zipdir(files_to_zip, OUTPUT_FILE_NAME)
upload_file_to_drive(OUTPUT_FILE_NAME, GDRIVE_FOLDER_ID)
os.remove(OUTPUT_FILE_NAME)