# Initial Class Plan #

## Core Classes ##

- TCEBaseApplication - Base application class to separate the engine from the target platform.  Descendants:-
	- TCEWindowsApplication
	- TCEIOSApplication
	- TCEAndroidApplication
	- TCEOSXApplication
- TCEBaseRenderer - Base renderer class to separate the engine from the target graphics API (GAPI).  Descendants:-
	- TCEOpenGLRenderer - Should support Windows, Mac OSX and Linux
	- TCEOpenGLESRenderer - Should support Android and iOS
	- TCEDirectXRenderer - Should support Windows
- TCECore - Core engine class, uses platform/API specific classes to perform required actions
- TCEBaseInput - Base input handling class.  Uses instances of platform specific handler classes to handle user input.  The appropriate base classes should be created by descendants to TCEBaseApplication.  
	- TCEBaseMouseInput - Base mouse input class
		- TCEWindowsMouseInput
		- TCEOSXMouseInput
		- etc.
	- TCEBaseKeyboardInput - Base keyboard input class
		- TCEWindowsKeyboardInput
		- TCEOSXKeyboardInput
		- etc.
- TCEBaseAudio - Base audio handling class.  Descendants:-
	- TCEOpenALAudio
- TCEBasePhysics - Base physics handling class.  Descendants should implement specific physics APIs.
	- TCENewtonPhysics
- TCE2D - 2D handling class.  Uses the chosen renderer to implement a 2D environment for sprites etc.
- TCEGUI - Graphical User Interface (GUI) handling class.
	- TCEConsole - Provides a simple text based console
- TCEBaseNetwork - Base network interface class
	- TCEIndyNetwork - Indy implementation of the network interface
	- TCESynapseNetwork - Synapse implementation of the network interface
- TCEEntityManager - System entity manager class
- TCESceneGraphDatabase - System scene graph database class
- TCEMediaLibrary - System media library class.  Implements file system handling via the application class.
- TCESubsystemManager - Provides a means by which the user application can query the available sub-systems (for operating preferences choices for example).  All sub-system classes are descended from TCESubSystem which registers the descendant class with the manager.  The manager then allows simple queries such as 'findAudioInterfaces', 'findRenderers' to be performed. 

## Core Class Hierarchy ##

- TCECore
	- Application => TCEBaseApplication - Provides reference to platform specific application handler
	- Renderer => TCEBaseRenderer - Provides reference to current renderer
	- Audio => TCEBaseAudio - Provides reference to audio interface
	- Input => TCEBaseInput - Provides reference to input handler
	- Physics => TCEBasePhysics - Provides reference to physics handler
	- Network => TCEBaseNetwork - Provides reference to network handler
	- EntityManager => TCEEntityManager - Provides reference to the entity manager

References that are nil simply mean that functionality is not available.  For example, an OpenGL renderer on Windows with OpenAL audio:-

- TCECore
	- Application => TCEWindowsApplication
	- Renderer => TCEOpenGLRenderer
	- Audio => TCEOpenALAudio
	- Input => NIL
	- Physics => NIL
	- Network => NIL
	- EntityManager => TCEEntityManager

## Entity related classes ##

- TCEBaseEntity - Base class for all game entities.  Implements general functionality such as traversal of hierarchy etc.  Descendants (to be decided):-
	- TCEEntity - Basic entity
	- TCEPositionableEntity - Positionable entity (extends TCEEntity, provides position and orientation)
	- TCELightEntity - Positionable light source (extends TCEPositionableEntity, provides light configuration)
	
## Component related classes ##

- TCEBaseComponent - Base class for all components that can be attached to entities.  Descendants:-
	- TCEUpdater - Performs periodic updates to the entity to which it is attached
	- TCEMesh - Provides a model for the entity to which it is attached
	- TCESound - Attaches a sound to the entity to which it is attached
	- TCECollisionVolume - Provides a collision volume for the entity to which it is attached allowing it to take part in collision detection tests
	- TCEMaterial - Provides a material for the entity to which it is attached
	- TCELight - Provides a light source
	
- TCEBaseComponentConfig - Base class for localised component configuration (i.e. specific animation frame, specific orientation... i.e. elements that are specific to an instance of an entity).  These should be created and attached to the entity by the component being attached. 

## Zone/Portal related classes ##

These classes are technical rendering classes designed to allow optimisation of the rendering pipeline taking into account entities that are visible from inside a given zone.

- TCEZone - Forms a rendering/model zone (e.g. an interior room) allowing a larger model to be broken up to optimise rendering
- TCEPortal - Joins two TCEZones together forming a viewport through zone boundaries.

## Utility Classes/Records ##

- TCEVec2D
- TCEVec3D
- TCEMatrix
- TCEEventingFabric - Provides a simple eventing fabric that allows events to be raised and sent to 'subscribers'.

## Other Proposed Classes ##

- TCEHighscoreTable - Provides an on-line/locally stored high score table
- TCEAchievementManager - Provides an on-line/locally stored achievement system
- TCEBaseLogger - Provides a base logging class.  Descendants provide different platform/logging system support.  Descendants-
	- TCEFileLogger - Provides simple file based logger
	- TCECodesiteLogger - Provides a CodeSite based logger (for Windows)
	- TCETCPLogger - Provides a simple TCP socket based logger