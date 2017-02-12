enum Compression { None, Gzip }

const Map<String, Compression> compressionMapper = const {
  'NONE': Compression.None,
  'GZIP': Compression.Gzip
};
