import os
import zipfile
import shutil

def package():
    base_dir = r"d:\PTAPP\projectsth1"
    output_zip = r"d:\PTAPP\projectsth1_NgoTuanAnh_2351170570.zip"
    
    if os.path.exists(output_zip):
        os.remove(output_zip)

    include_dirs = ['lib', 'test', 'android', 'web', 'windows']
    include_files = [
        'pubspec.yaml',
        'pubspec.lock',
        'analysis_options.yaml',
        'README.md',
        'BAO_CAO_TH1_KIEN_TRUC_CASHEW.md',
        'BAO_CAO_TH1_KIEN_TRUC_CASHEW_NgoTuanAnh_2351170570.docx'
    ]
    exclude_subdirs = {'.gradle', 'build', '.dart_tool', '.idea'}

    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for f in include_files:
            file_path = os.path.join(base_dir, f)
            if os.path.exists(file_path):
                zipf.write(file_path, arcname=f)
                
        for d in include_dirs:
            dir_path = os.path.join(base_dir, d)
            if not os.path.exists(dir_path):
                continue
            for root, dirs, files in os.walk(dir_path):
                # Filter out excluded directories in-place
                dirs[:] = [sub for sub in dirs if sub not in exclude_subdirs]
                for file in files:
                    if file.endswith('.lock'):
                        continue
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, base_dir)
                    zipf.write(full_path, arcname=rel_path)

    size = os.path.getsize(output_zip)
    print(f"SUCCESS: Packaged {output_zip} ({size} bytes, {size/1024:.1f} KB)")

if __name__ == '__main__':
    package()
