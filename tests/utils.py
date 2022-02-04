from itertools import chain

def dict_to_flat_tuple(data):
  return tuple(dict_to_flat_tuple(d) if type(d) is dict else d for d in data.values())
