import:py os;
import:py from pydrive.auth, GoogleAuth;
import:py from pydrive.drive, GoogleDrive;
import:py zipfile;
import:py datetime;

glob OUTPUT_FILE_NAME = f"results_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.zip";
glob GDRIVE_FOLDER_ID = os.environ['GDRIVE_FOLDER_ID'];

can zipdir(files: list, out:str) {
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zipf {
        for file in files {zipf.write(file);}
    }
}

can upload_file_to_drive(file: str, folder_id: str) {
    file_drive = drive.CreateFile({'parents': [{'id': folder_id}]});
    file_drive.SetContentFile(file);
    file_drive.Upload();
}

with entry {
    gauth = GoogleAuth();
    gauth.LocalWebserverAuth();
    drive = GoogleDrive(gauth);

    files_to_zip = [os.path.join('results', file) for file in os.listdir('results')];
    zipdir(files_to_zip, OUTPUT_FILE_NAME);
    upload_file_to_drive(OUTPUT_FILE_NAME, GDRIVE_FOLDER_ID);
    os.remove(OUTPUT_FILE_NAME);
}