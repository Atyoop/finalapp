import json
import os
import re
import subprocess

def main():
    # Run flutter analyze --machine
    # We ignore exit code since it exits with 1 if there are errors
    process = subprocess.run(['flutter', 'analyze', '--machine'], capture_output=True, text=True, shell=True)
    lines = process.stdout.split('\n')
    
    errors = []
    for line in lines:
        if line.startswith('ERROR|COMPILE_TIME_ERROR|INVALID_CONSTANT|'):
            parts = line.split('|')
            if len(parts) >= 8:
                file_path = parts[3]
                line_num = int(parts[4])
                col_num = int(parts[5])
                errors.append((file_path, line_num, col_num))
                
    if not errors:
        print("No INVALID_CONSTANT errors found.")
        return

    # Group by file
    files_to_fix = {}
    for f, l, c in errors:
        files_to_fix.setdefault(f, []).append((l, c))
        
    for file_path, locs in files_to_fix.items():
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            lines_content = f.read().split('\n')
            
        # Sort locations descending so line number changes don't affect previous
        # We're just modifying text in place on existing lines, so it's fine
        locs = sorted(list(set(locs)), key=lambda x: -x[0])
        
        for l, c in locs:
            idx = l - 1 # 0-indexed
            # We want to remove the 'const ' keyword near this error.
            # Usually it's on the same line or within the 5 previous lines
            for offset in range(10):
                target_idx = idx - offset
                if target_idx < 0:
                    break
                line_str = lines_content[target_idx]
                if 'const ' in line_str:
                    # Remove the last occurrence of 'const ' on this line
                    # Or just remove 'const ' and keep spaces
                    modified = re.sub(r'\bconst\s+', '', line_str)
                    if modified != line_str:
                        lines_content[target_idx] = modified
                        print(f"Fixed const in {file_path}:{target_idx+1}")
                        break
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines_content))

if __name__ == '__main__':
    main()
