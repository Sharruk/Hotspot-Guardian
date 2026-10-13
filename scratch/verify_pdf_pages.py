import fitz
import os

pdf_path = 'documentation/Hotspot_Guardian_Project_Report.pdf'
doc = fitz.open(pdf_path)
print(f"Total pages in document: {len(doc)}")

preview_dir = 'scratch/pdf_previews'
os.makedirs(preview_dir, exist_ok=True)

for i in range(len(doc)):
    page = doc[i]
    pix = page.get_pixmap(dpi=150)
    out_img = os.path.join(preview_dir, f"page_{i+1:02d}.png")
    pix.save(out_img)
    text = page.get_text().strip()
    first_line = text.split('\n')[0] if text else '[EMPTY]'
    print(f"Page {i+1:02d}: {page.rect.width:.0f}x{page.rect.height:.0f} pt | Text chars: {len(text):4d} | Header/First Line: '{first_line[:50]}'")

print("Rendered all page previews to scratch/pdf_previews/")
