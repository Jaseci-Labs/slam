import:py os;
import:py from pydrive.auth, GoogleAuth;
import:py from pydrive.drive, GoogleDrive;
import:py zipfile;
import:py datetime;

glob current_time = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S');
glob GDRIVE_FOLDER_ID = os.environ['GDRIVE_FOLDER_ID'];

can zipdir(folders:list[str], out:str) {
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zipf {
        for folder in folders {
            for (root, _, files) in os.walk(folder) {
                for file in files {
                    zipf.write(os.path.join(root, file), 
                        os.path.relpath(os.path.join(root, file), 
                        os.path.join(folder, '..')));
                }
            }
        }
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

    zipdir([".human_eval_config", "results", "data"], f"{current_time}.zip");
    upload_file_to_drive(f"{current_time}.zip", GDRIVE_FOLDER_ID);
    os.remove(f"{current_time}.zip");
}