require 'mini_magick'

image = MiniMagick::Image.open('example.HEIC')
image.type # => "HEIC"
image.format = "jpeg"
image.write('output.jpg')
