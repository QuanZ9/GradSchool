import read_data
import pandas as pd

class sic_io_mapping:
	def __init__(self):
		self.io2sic_dict = read_data.read_sic_io(read_data.sic_io_path)
		self.sic2io_dict = dict()
		for key, value in self.io2sic_dict.iteritems():
			for v in value:
				if v not in self.sic2io_dict.keys():
					self.sic2io_dict[v] = [key]
				else:
					self.sic2io_dict[v].append(key)


	def sic2io(self, sic):
		if sic in self.sic2io_dict.keys():
			return self.sic2io_dict[sic]
		else:
			return None

	def io2sic(self, io):
		if io in self.io2sic_dict.keys():
			return self.io2sic_dict[io]
		else:
			return None

if __name__ == "__main__":
	sic_io = sic_io_mapping()
	print
	print sic_io.io2sic("780500")
