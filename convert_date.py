import re

def convert_date(match):
    year = match.group(1)
    day = match.group(2)
    month = match.group(3)
    print(f"{year}-{day}-{month} -> {year}-{month}-{day}")
    return f"{year}-{month}-{day}"

def main():
    input_file = 'text.txt'  # Replace with your file name
    output_file = 'output_file.txt'  # Replace with your output file name
    
    with open(input_file, 'r', encoding='utf-8') as file:
        text = file.read()
    
    # Define the regex pattern to find dates in the format yyyy-dd-mm
    pattern = r'\b(\d{4})-(\d{2})-(\d{2})\b'
    
    # Use re.sub to replace all occurrences of the pattern with the converted date format
    converted_text = re.sub(pattern, convert_date, text)
    
    # Write the modified text to the output file
    with open(output_file, 'w', encoding='utf-8') as nfile:
        nfile.write(converted_text)
    
    print(f"Conversion successful. Converted content saved to '{output_file}'.")

if __name__ == "__main__":
    main()