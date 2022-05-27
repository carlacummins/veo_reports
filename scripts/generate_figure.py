import sys
import argparse

from PIL import Image, ImageFont, ImageDraw 

def add_margin(pil_img, top, right, bottom, left, color):
    width, height = pil_img.size
    new_width = width + right + left
    new_height = height + top + bottom
    result = Image.new(pil_img.mode, (new_width, new_height), color)
    result.paste(pil_img, (left, top))
    return result

def annotate(img_raw, text):
    img = add_margin(img_raw, 0, 5, 0, 50, (255,255,255))
    img_draw = ImageDraw.Draw(img)
    fnt = ImageFont.truetype("assets/arial.ttf", 40)
    img_draw.text((5,10), text, (0, 0, 0), font=fnt)
    return img

parser = argparse.ArgumentParser(description="Stitch input together into a single figure with letter annotations")
parser.add_argument('-i', '--input', help="input files (comma separated)")
parser.add_argument('-o', '--output', help="output file")
opts = parser.parse_args(sys.argv[1:])

input_files = opts.input

annotations = ["A", "B", "C", "D"]
x = 0
annot_imgs = []
for img_file in input_files.split(","):
    img_raw = ''
    try:
        img_raw = Image.open(img_file)
    except FileNotFoundError:
        sys.stderr.write(f"generate_figure.py : Cannot open file {img_file}\n")
        sys.exit(1)
    img = annotate(img_raw, annotations[x])
    annot_imgs.append(img)
    x += 1

fig_width = max([i.width for i in annot_imgs])
fig_height = sum([i.height for i in annot_imgs])
fig = Image.new('RGB', (fig_width, fig_height))
rolling_height = 0
for img in annot_imgs:
    fig.paste(img, (0, rolling_height))
    rolling_height += img.height

fig.save(opts.output)
