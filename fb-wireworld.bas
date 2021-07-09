#include once "fbgfx.bi"
#include once "file.bi"

/'
  A simple class that implements the Wireworld cellular
  automata.
'/
type Wireworld
  public:
    declare constructor( as integer, as integer )
    declare destructor()
    
    declare operator cast() as Fb.Image ptr
    
    declare property width() as integer
    declare property height() as integer
    
    declare sub update()
    
  private:
    enum State
      Empty = rgba( 0, 0, 0, 255 )
      ElectronHead = rgba( 255, 255, 255, 255 )
      ElectronTail = rgba( 0, 128, 255, 255 )
      Connector = rgba( 0, 0, 64, 255 )
    end enum
    
    declare constructor()
    
    as Fb.Image ptr _circuit( 0 to 1 )
    as integer _
      _width, _
      _height, _
      _activeCircuit, _
      _backCircuit, _
      _headerSize = sizeof( Fb.Image ) \ sizeof( ulong )
end type

constructor Wireworld() : end constructor

constructor Wireworld( aWidth as integer, aHeight as integer )
  _activeCircuit = 0
  _backCircuit = 1
  
  _width = iif( aWidth < 100, 100, aWidth )
  _height = iif( aHeight < 100, 100, aHeight )
  
  for i as integer = 0 to 1
    _circuit( i ) = imageCreate( _width, _height, rgba( 0, 0, 0, 0 ) )
  next
end constructor

destructor Wireworld()
  for i as integer = 0 to 1
    imageDestroy( _circuit( i ) )
  next
end destructor

operator Wireworld.cast() as Fb.Image ptr
  return( _circuit( _activeCircuit ) )
end operator

property Wireworld.width() as integer
  return( _width )
end property

property Wireworld.height() as integer
  return( _height )
end property

sub Wireworld.update()
  #macro pixel( buffer, x, y )
    ( cptr( ulong ptr, buffer ) + _headerSize )[ buffer->width * y + x ]
  #endMacro
  
  for y as integer = 0 to _height - 1
    for x as integer = 0 to _width - 1
      dim as ulong _
        currentPixel = pixel( _circuit( _activeCircuit ), x, y )
      
      select case( currentPixel )
        case( State.ElectronHead )
          pixel( _circuit( _backCircuit ), x, y ) = State.ElectronTail
        
        case( State.ElectronTail )
          pixel( _circuit( _backCircuit ), x, y ) = State.Connector
        
        case( State.Connector )
          dim as integer neighbors
          
          for yy as integer = y - 1 to y + 1
            for xx as integer = x - 1 to x + 1
              if( _
                xx >= 0 andAlso xx <= _width - 1 andAlso _
                yy >= 0 andAlso yy <= _height - 1 ) then
                
                if( pixel( _circuit( _activeCircuit ), xx, yy ) = State.ElectronHead ) then
                  neighbors += 1
                end if
              end if
            next
          next
          
          if( neighbors = 1 orElse neighbors = 2 ) then
            pixel( _circuit( _backCircuit ), x, y ) = State.ElectronHead
          else
            pixel( _circuit( _backCircuit ), x, y ) = State.Connector
          end if
        
        case else
          pixel( _circuit( _backCircuit ), x, y ) = pixel( _circuit( _activeCircuit ), x, y )
      end select
    next
  next
  
  swap _activeCircuit, _backCircuit
  
  #undef pixel
end sub

/'
  Test code
'/
screenRes( 800, 600, 32 )
windowTitle( "FreeBasic Wireworld!" )

var aCircuit = new Wireworld( 800, 600 )

bload( "prime-computer.bmp", *aCircuit )

do
  aCircuit->update()
  
  screenLock()
    put ( 0, 0 ), *aCircuit, pset
  screenUnlock()
  
  sleep( 1, 1 )
loop until( len( inkey() ) )

delete( aCircuit )
