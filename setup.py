from setuptools import setup

def local_scheme(version):
  """Skip the local version (eg. +xyz of 0.6.1.dev4+gdf99fe2)
  to be able to upload to Test PyPI"""
  return ""

if __name__ == "__main__":
  try:
    setup(use_scm_version={'local_scheme': local_scheme})
  except:  # noqa
    print(
      "\n\nAn error occurred while building the project, "
      "please ensure you have the most updated version of setuptools, "
      "setuptools_scm and wheel with:\n"
      "   pip install -U setuptools setuptools_scm wheel\n\n"
    )
    raise
