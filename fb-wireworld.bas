#include once "fbgfx.bi"
#include once "file.bi"

enum State
  Empty => rgba( 0, 0, 0, 255 )
  ElectronHead => rgba( 255, 255, 255, 255 )
  ElectronTail => rgba( 0, 128, 255, 255 )
  Connector => rgba( 0, 0, 64, 255 )
end enum
 
type WireWorld
  public:
    declare constructor( _
      byval as integer, _
      byval as integer )
    declare destructor()
    
    declare operator _
      cast() as Fb.Image ptr
    declare property _
      width() as integer
    declare property _
      height() as integer
    declare property _
      circuit() as Fb.Image ptr
    
    declare sub _
      update()
    
  private:
    declare constructor()
    
    as Fb.Image ptr _
      m_circuit( 0 to 1 )
    as integer _
      m_width, _
      m_height, _
      m_activeCircuit, _
      m_backCircuit, _
      headerSize => sizeOf( Fb.Image ) \ 4
end type

constructor _
  WireWorld()
end constructor

constructor _
  WireWorld( _
    byval aWidth as integer, _
    byval aHeight as integer )
  
  m_activeCircuit => 0
  m_backCircuit => 1
  
  m_width => iif( _
    aWidth < 100, 100, aWidth )
  m_height => iif( _
    aHeight < 100, 100, aHeight )
  
  for _
    i as integer => 0 to 1
    
    m_circuit( i ) => imageCreate( _
      m_width, m_height, rgba( 0, 0, 0, 0 ) )
  next
end constructor

destructor _
  WireWorld()
  
  for _
    i as integer => 0 to 1
    
    imageDestroy( m_circuit( i ) )
  next
end destructor

operator _
  WireWorld.cast() _
  as Fb.Image ptr
  
  return( m_circuit( m_activeCircuit ) )
end operator

property _
  WireWorld.width() _
  as integer
  
  return( m_width )
end property

property _
  WireWorld.height() _
  as integer
  
  return( m_height )
end property

property _
  WireWorld.circuit() _
  as Fb.Image ptr
  
  return( m_circuit( m_backCircuit ) )
end property

sub _
  WireWorld.update()
  
  #macro pixel( buffer, x, y )
    ( cptr( _
      ulong ptr, _
      buffer ) + headerSize )[ buffer->width * y + x ]
  #endMacro
  
  '#macro countNeighbor( _
  '  buffer, x, y, counter )
  '  
  '  counter +=> iif( _
  '    x >= 0 andAlso _
  '    y >= 0 andAlso _
  '    x <= m_width - 1 andAlso _
  '    y <= m_height - 1 andAlso _
  '    pixel( buffer, x, y ) = State.ElectronHead, _
  '    1, 0 )
  '#endmacro
  
  for _
    y as integer => 0 to m_height - 1
    
    for _
      x as integer => 0 to m_width - 1
      
      dim as ulong _
        currentPixel => _
          pixel( _
            m_circuit( m_activeCircuit ), x, y )
          
      select case( currentPixel )
        case( State.ElectronHead )
          pixel( _
            m_circuit( m_backCircuit ), x, y ) => State.ElectronTail
          
        case( State.ElectronTail )
          pixel( _
            m_circuit( m_backCircuit ), x, y ) => State.Connector
          
        case( State.Connector )
          dim as integer _
            neighbors
          
          for _
            yy as integer => y - 1 to y + 1
            
            for _
              xx as integer => x - 1 to x + 1
              
              if( _
                xx >= 0 andAlso xx <= m_width - 1 andAlso _
                yy >= 0 andAlso yy <= m_height - 1 ) then
                
                if( _
                  pixel( _
                    m_circuit( m_activeCircuit ), xx, yy ) = State.ElectronHead ) then
                  
                  neighbors += 1
                end if
              end if
            next
          next
          
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x - 1, y - 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x, y - 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x + 1, y - 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x + 1, y, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x + 1, y + 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x, y + 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x - 1, y + 1, _
          '  neighbors )
          'countNeighbor( _
          '  m_circuit( m_activeCircuit ), _
          '  x - 1, y, _
          '  neighbors )
          
          if( _
            neighbors = 1 orElse _
            neighbors = 2 ) then
            
            pixel( _
              m_circuit( m_backCircuit ), x, y ) => State.ElectronHead
          else
            pixel( _
              m_circuit( m_backCircuit ), x, y ) => State.Connector
          end if
        
        case else
          pixel( _
            m_circuit( m_backCircuit ), x, y ) => _
            pixel( _
              m_circuit( m_activeCircuit ), x, y )
      end select
    next
  next
  
  swap _
    m_activeCircuit, _
    m_backCircuit
  
  #undef pixel
  #undef countNeighbor
end sub

/'
  Test code
'/
screenRes( 800, 600, 32 )

var aCircuit => new WireWorld( 800, 600 )

bload( "prime-computer.bmp", *aCircuit )

do
  aCircuit->update()
  
  screenLock()
    put _
      ( 0, 0 ), _
      aCircuit->circuit, pset
  screenUnlock()
  
  sleep( 1, 1 )
loop _
  until( inkey() <> "" )

delete( aCircuit )