from PIL import Image

# Open the PNG file
img = Image.open('assets/icon.png')

# Define icon sizes for Windows
sizes = [(256,256), (128,128), (64,64), (48,48), (32,32), (16,16)]

# Save as .ico with multiple sizes
img.save('windows/runner/resources/app_icon.ico', format='ICO', sizes=sizes)

