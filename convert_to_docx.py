import markdown
import os

with open("dr_horria_poster.txt", "r", encoding="utf-8") as f:
    text = f.read()

# Convert markdown to html
html_body = markdown.markdown(text, extensions=['tables'])

# Ensure absolute path for image so textutil can find it
abs_path = os.path.abspath("dr_horria_robot.jpg")
html_body = html_body.replace('src="dr_horria_robot.jpg"', f'src="file://{abs_path}"')

# Wrap in html with styles for justified text
html_content = f"""
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{
    font-family: Arial, sans-serif;
  }}
  p {{
    text-align: justify;
  }}
  table {{
    border-collapse: collapse;
    width: 100%;
  }}
  th, td {{
    border: 1px solid black;
    padding: 8px;
    text-align: left;
  }}
  img {{
    max-width: 100%;
    height: auto;
  }}
</style>
</head>
<body>
{html_body}
</body>
</html>
"""

with open("poster.html", "w", encoding="utf-8") as f:
    f.write(html_content)
