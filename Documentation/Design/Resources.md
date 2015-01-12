# Resources
All resources (images, texts, shaders, sounds etc) are represented by a special kind of entity of base class CEResource.
Format property specifies how data is stored (pixel format, audio samples etc).
CEResource descendants can store data by itself as a binary property or use an external storage.
In latter case the Data Loader and Data Decoder mechanisms will be used.
Externally stored resource can be loaded directly into a target destination (video memory etc) bypassing system memory.
Resource data can be converted between various formats via Data Converter mechanism.

### Resource loading from external storage process into resource data in memory
- obtain data loader class by URL
- use data loader to get input stream by URL
- obtain data decoder class by URL
- use decoder to load data

Data in external storage may affect resource metadata such as format, width/height for images etc.
Therefore loading into custom target should be performed in three phases:

1. metadata loading 
2. custom target prepare
3. data loading

## Data Loader mechanism
Data Loader mechanism allows to register and query data loaders - descendants of TCEDataLoader class.
A data loader's task is to create an input stream of data based on an URL which has the following format:

	protocol://address/path/filename.ext

All parts except filename are optional.
Protocol determines where to URL is pointing to: file on local file system (default), file over http or ftp, data within archive etc.
Examples:

	file://c:/data/image.png - will open file input stream with the file data
	http://www.site.com/data/mesh.obj - will open network input stream with the file data

## Data Decoder mechanism
Data Decoder mechanism allows to register and query data decoders - descendants of TCEDataDecoder  class.
Each data decoder class contains list of supported data format IDs.
A data decoder implements decoding of data stored in some format for a certain class of entity.
For example when loading an image TCEImage is the entity class and data format can be say .bmp, .png etc.
