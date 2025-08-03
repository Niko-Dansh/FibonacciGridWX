import os

EXTENSIONS = {'.py', '.csv', '.yaml', '.env', '.txt'}  # расширения, которые собирать
OUTFILE = 'all_code.txt'

with open(OUTFILE, 'w', encoding='utf-8') as outf:
    for root, dirs, files in os.walk(r'C:\Users\naunn\PycharmProjects\FibonacciGridWX'):
        # пропустим папку venv или .git
        if any(part in ('venv', '.git') for part in root.split(os.sep)):
            continue
        for fname in files:
            ext = os.path.splitext(fname)[1].lower()
            if ext in EXTENSIONS:
                path = os.path.join(root, fname)
                outf.write(f"\n=== File: {path} ===\n")
                with open(path, 'r', encoding='utf-8', errors='ignore') as inf:
                    outf.write(inf.read())
