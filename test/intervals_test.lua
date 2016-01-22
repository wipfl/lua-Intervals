EXPORT_ASSERT_TO_GLOBALS = true
require('luaunit')
require('math')
iv=require('intervals')

TestIntervals = {}


function TestIntervals:test_initialize()
  local a = iv:new({l=99,v=100,h=101})

  -- Standard initializer  
  assertEquals(a.value, 100)
  assertEquals(a.low,99)
  assertEquals(a.high,101)

  -- Initialize with a number
  local b = iv:new(122.3)
  assertEquals(b.value, 122.3)
  assertEquals(b.low,122.3)
  assertEquals(b.high,122.3)

  -- Initialize with delta
  b = iv:new{v=10,d=0.05}
  assertEquals(b.value, 10)
  assertEquals(b.low,10-0.05)
  assertEquals(b.high,10+0.05)
  
  -- Initialize with delta around 0
  b = iv:new{v=1, d=2}
  assertEquals(b.value, 1)
  assertEquals(b.low,1-2)
  assertEquals(b.high,1+2)
  
  -- Initialize with negative delta around 0
  b = iv:new{v=1, d=-2}
  assertEquals(b.value, 1)
  assertEquals(b.low,1-2)
  assertEquals(b.high,1+2)
  
  -- Initialize with negative delta around 10
  b = iv:new{v=10, d=-2}
  assertEquals(b.value, 10)
  assertEquals(b.low,10-2)
  assertEquals(b.high,10+2)
  
  -- Initialize with interval in wrong sequence
  b = iv:new{v=10, l = 11, h=-2}
  assertEquals(b.value, 10)
  assertEquals(b.low,-2)
  assertEquals(b.high,11)
  
  -- Initialize with interval that doesn't contain the value (should be adapted)
  b = iv:new{v=10, l = 11, h=12}
  assertEquals(b.value, 10)
  assertEquals(b.low,10)
  assertEquals(b.high,12)
  
  -- Initialize with interval that doesn't contain the value (should be adapted)
  b = iv:new{v=10, l = 9, h=9.5}
  assertEquals(b.value, 10)
  assertEquals(b.low,9)
  assertEquals(b.high,10)

  -- Test for assertion with wrong type
  local function new(b) return iv:new(b); end
  
  local ok, res = pcall(new,'string')
  assertFalse(ok)
  assertStrContains(res, 'Initializer must be a table or a number')
  
end

function TestIntervals:test_min_max()
  -- Check _min
  assertEquals(iv._min{1,2,3,4,5}, 1)
  assertEquals(iv._min{-1,2,-3,4,-5}, -5)
  assertEquals(iv._min{-1,math.huge}, -1)
  assertEquals(iv._min{-1,-math.huge}, -math.huge)
  assertEquals(iv._min{-5}, -5)

  -- Check _max
  assertEquals(iv._max{1,2,3,4,5}, 5)
  assertEquals(iv._max{-1,2,-3,4,-5}, 4)
  assertEquals(iv._max{-1,math.huge}, math.huge)
  assertEquals(iv._max{-1,-math.huge}, -1)
  assertEquals(iv._max{-5}, -5)
end

function TestIntervals:test_normalize()
  local a = iv:new({l=9.5,v=10,h=10.3})
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  
  -- Standard
  a:normalize()
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  
  -- low, value, high are equal
  a.low = a.value
  a.high = a.value
  a:normalize()
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  
  -- value is lower than low
  a.value = a.low - 1
  a:normalize()
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  assertEquals(a.low == a.value, true)
  
  -- value is higher than high
  a.value = a.high + 1
  a:normalize()
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  assertEquals(a.high == a.value, true)

  -- high and low are changed
  a.low = 11
  a.high = 10
  a.value = 9.5  
  a:normalize()
  assertEquals(a.low <= a.value, true )
  assertEquals(a.value <= a.high, true )
  assertEquals( a.value == 9.5, true)

end

function TestIntervals:test_add()
  local a = iv:new({l=9.5,v=10,h=10.3})
  local b = iv:new({h=-9.5,v=-10,l=-10.8})
  
  
  local ok, res, c
  
  c = a+b
  assertEquals(c.value,  0)
  assertAlmostEquals(c.low,   -1.3, 1e-12)
  assertAlmostEquals(c.high,   0.8, 1e-12)

  c = b+a
  assertEquals(c.value,  0)
  assertAlmostEquals(c.low,   -1.3, 1e-12)
  assertAlmostEquals(c.high,   0.8, 1e-12)

  -- Single Point Interval
  a = iv:new({l=10,v=10,h=10})
  b = iv:new({h=1,v=1,l=1})

  c = a+b
  assertEquals(c.value, 11)
  assertEquals(c.low,   11)
  assertEquals(c.high,  11)

  c = b+a
  assertEquals(c.value, 11)
  assertEquals(c.low,   11)
  assertEquals(c.high,  11)

end

function TestIntervals:test_sub()
  local a = iv:new({l=9.5,v=10,h=10.3})
  local b = iv:new({h=-9.5,v=-10,l=-10.8})
  
  
  local ok, res, c
  
  c = a-b
  assertEquals(c.value,       a.value - b.value)
  assertAlmostEquals(c.low,   a.low - b.high, 1e-12)
  assertAlmostEquals(c.high,  a.high - b.low, 1e-12)

  c = b-a
  assertEquals(c.value,       b.value - a.value)
  assertAlmostEquals(c.low,   b.low - a.high, 1e-12)
  assertAlmostEquals(c.high,  b.high - a.low, 1e-12)

  -- Single Point Interval
  a = iv:new({l=10,v=10,h=10})
  b = iv:new({h=1,v=1,l=1})

  c = a-b
  assertEquals(c.value, 9)
  assertEquals(c.low,   9)
  assertEquals(c.high,  9)

  c = b-a
  assertEquals(c.value, -9)
  assertEquals(c.low,   -9)
  assertEquals(c.high,  -9)
  
  -- First Operand is number
  local d = 12
  a = iv:new({l=9.5,v=10,h=10.3})
  b = iv:new({h=-9.5,v=-10,l=-10.8})
  
  c = d - a
  assertEquals(c.value,  2)
  assertAlmostEquals(c.low,   d- a.high, 1e-12)
  assertAlmostEquals(c.high,  d- a.low, 1e-12)
  
  c = d - b
  assertEquals(c.value,  22)
  assertAlmostEquals(c.low,   d - b.high, 1e-12)
  assertAlmostEquals(c.high,  d - b.low, 1e-12)
  
  -- Second Operand is number
  local d = 12
  a = iv:new({l=9.5,v=10,h=10.3})
  b = iv:new({h=-9.5,v=-10,l=-10.8})
  
  c = a - d
  assertEquals(c.value,  -2)
  assertAlmostEquals(c.low,   a.low - d, 1e-12)
  assertAlmostEquals(c.high,  a.high -d, 1e-12)
  
  c = b - d
  assertEquals(c.value,  -22)
  assertAlmostEquals(c.low,   b.low - d, 1e-12)
  assertAlmostEquals(c.high,  b.high -d, 1e-12)
  
  
end


function TestIntervals:test_unm()
  local a = iv:new({l=9.5,v=10,h=10.3})
  local c
  
  c = -a
  assertEquals(c.value, -a.value)
  assertEquals(c.low,   -a.high)
  assertEquals(c.high,  -a.low)

  c = - -a
  assertEquals(c.value, a.value)
  assertEquals(c.low,   a.low)
  assertEquals(c.high,  a.high)
  
end


function TestIntervals:test_mul()
  local a = iv:new({l=9.5,v=10,h=10.3})
  local b = iv:new({l=-9.5,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  
  local c
  -- Simple case: both positive
  c = a*a
  assertEquals(c.value, 100)
  assertEquals(c.low,a.low*a.low)
  assertEquals(c.high,a.high*a.high)

  -- One limit negative  
  c = a*b
  assertEquals(c.value, 100)
  assertEquals(c.low,a.high*b.low)
  assertEquals(c.high,a.high*b.high)
  
  c = b*a
  assertEquals(c.value, 100)
  assertEquals(c.low,a.high*b.low)
  assertEquals(c.high,a.high*b.high)

  -- All values of one operand negative
  c = a*d
  assertEquals(c.value, -100)
  assertEquals(c.low,a.high*d.low)
  assertEquals(c.high,a.low*d.high)
    
  c = d*a
  assertEquals(c.value, -100)
  assertEquals(c.low,a.high*d.low)
  assertEquals(c.high,a.low*d.high)
 
  -- All values of both operands negative
  c = d*d
  assertEquals(c.value, 100)
  assertEquals(c.low,d.high*d.high)
  assertEquals(c.high,d.low*d.low)
  
  -- Multiply with number
  c = 2*b
  assertEquals(c.value, 20)
  assertEquals(c.low,2*b.low)
  assertEquals(c.high,2*b.high)
  
  c = b*2
  assertEquals(c.value, 20)
  assertEquals(c.low,2*b.low)
  assertEquals(c.high,2*b.high)
  
  c= -2*b
  assertEquals(c.value, -20)
  assertEquals(c.low,-2*b.high)
  assertEquals(c.high,-2*b.low)
    
end
  
function TestIntervals:test_div()
  local a = iv:new({l=9.5,v=10,h=10.3})
  local b = iv:new({l=-9.5,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  
  local c
  -- Simple case: both positive
  c = a/a
  assertEquals(c.value, 1)
  assertAlmostEquals(c.low,a.low/a.high,1e-12)
  assertAlmostEquals(c.high,a.high/a.low,1e-12)
  
  -- All values of one operand negative
  c = a/d
  assertEquals(c.value, -1)
  assertAlmostEquals(c.low,a.high/d.high,1e-12)
  assertAlmostEquals(c.high,a.low/d.low,1e-12)
    
  c = d/a
  assertEquals(c.value, -1)
  assertAlmostEquals(c.low,d.low/a.low,1e-12)
  assertAlmostEquals(c.high,d.high/a.high,1e-12)
 
  -- Dividend One limit negative  
  c = b/a
  assertEquals(c.value, 1)
  assertEquals(c.low,b.low/a.low)
  assertEquals(c.high,b.high/a.low)
  
  -- Divisor One limit negative  / now 0 is in the interval
  -- this gives result interval from minus infinity to plus infinity
  c = a/b
  assertEquals(c.value, 1)
  assertEquals(c.low,- math.huge)
  assertEquals(c.high, math.huge)

  -- Dividend is a number / Divisor all positive
  c = 2/a 
  assertEquals(c.value, 2/a.value)
  assertEquals(c.low, 2 / a.high)
  assertEquals(c.high, 2 / a.low)
  

  -- Dividend is a number / Divisor contains Zero.
  c = 2/b 
  assertEquals(c.value, 2/a.value)
  assertEquals(c.low, - math.huge)
  assertEquals(c.high, math.huge)
  
end
  
--[[ 
function TestIntervals:test_sqrt()
  local a = iv:new('a', -100, 'm')
  local b = iv:new('b', 12, 'ms')
  local s = iv:new('s', 144, 'm/s')
  
  
  local c
  
  c = s:sqrt()
  assertEquals(c.value, 12)
  assertEquals(c.units.m,0.5)
  assertEquals(c.units.s,-0.5)
  assertEquals(c.symbol,nil)
 
 
  c = b*b
  c = c:sqrt()
  assertEquals(b==c, true)
  
  local function _sqrt(v) return v:sqrt(); end
  
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_sqrt, a)
  assertFalse(ok)
  assertStrContains(res,'sqrt of negative values not supported.')
  
end

function TestIntervals:test_cbrt()
  local a = iv:new('a', -100, 'm')
  local b = iv:new('b', 12, 'ms')
  local s = iv:new('s', 12*12*12, 'm/s')
  
  
  local c
  
  c = s:cbrt()
  assertAlmostEquals(c.value, 12, 1e-12)
  assertEquals(c.units.m,1/3)
  assertEquals(c.units.s,-1/3)
  assertEquals(c.symbol,nil)
 
  c = b*b*b
  c = c:cbrt()
  --assertEquals(b==c, true)
  -- b and c is not exactly equal (floating point rounding)
  -- We test if it is nearly equal
  
  assertAlmostEquals(c.value, b.value, 1e-12)
  assertAlmostEquals(c.units.s, b.units.s, 1e-12)
  

  local function _cbrt(a) return a:cbrt(); end
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_cbrt, a)
  assertFalse(ok)
  assertStrContains(res,'cbrt of negative values not supported.')
  
end


function TestIntervals:test_pow()
  local d = iv:new('d', 0, 'N')
  local s = iv:new('s', 12, 'm/s')
  
  local c
  
  c = s^2
  assertEquals(c.value, 12*12)
  assertEquals(c.units.m,2)
  assertEquals(c.units.s,-2)
  assertEquals(c.symbol,nil)
  

  c = s^-2
  assertEquals(c.value, 1/(12*12))
  assertEquals(c.units.m,-2)
  assertEquals(c.units.s,2)
  assertEquals(c.symbol,nil)
  
  c = d^-1
  assertEquals(c.value, math.huge)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.kg, -1)
  assertEquals(c.units.s,2)
  assertEquals(c.symbol,nil)
end
  
function TestIntervals:test_eq()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 100, 's')
  
  local c = a
  assertEquals(a==a, true)
  assertEquals(c==a, true)
  assertEquals(c==1*a, true)
  assertEquals(c==(1+1e-12)*a, false)
  assertEquals(c~=(1+1e-12)*a, true)
  assertEquals(a==b, false)
  assertEquals(a~=b, true)
end

function TestIntervals:test_lt()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 100, 's')
  
  local c = a
  assertEquals(a<a, false)
  assertEquals(a>a, false)
  assertEquals(c<a, false)
  assertEquals(c>a, false)
  assertEquals(c<(1+1e-12)*a, true)
  assertEquals(c>(1+1e-12)*a, false)
  assertEquals((1+1e-12)*a>c, true)
  assertEquals((1+1e-12)*a<c, false)
  
  function _lt(a,b) return a < b; end
  
  local ok, res
  ok, res = pcall(_lt,a,b)
  assertFalse(ok)
  assertStrContains(res, "Unmatching unit in compare <:")
end

function TestIntervals:test_le()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 100, 's')
  
  local c = a
  assertEquals(a<=a, true)
  assertEquals(a>=a, true)
  assertEquals(c<=a, true)
  assertEquals(c>=a, true)
  assertEquals(c<=(1+1e-12)*a, true)
  assertEquals(c>=(1+1e-12)*a, false)
  assertEquals((1+1e-12)*a>=c, true)
  assertEquals((1+1e-12)*a<=c, false)
  
  function _le(a,b) return a <= b; end
  
  local ok, res
  ok, res = pcall(_le,a,b)
  assertFalse(ok)
  assertStrContains(res, "Unmatching unit in compare <=:")
  
end


function TestIntervals:test_tostring()
  local a = iv.u['m'] / iv.u['s']
  a:setPrefUnit('m/s')
  assertStrMatches(tostring(a), '1 m/s')
end

function TestIntervals:test_format()
  local vMax = iv:new('vMax', 4, 'm/s')
  assertEquals(vMax:format(), '4 m/s')
  assertEquals(vMax:format(nil, 'km/h'), '14.4 km/h')
  assertEquals(vMax:format('#is #vg #us', nil), 'vMax 4 m/s')
  assertEquals(vMax:format('#is #vg #us', 'km/h'), 'vMax 14.4 km/h')
  assertEquals(vMax:format('#is #vg #us', 'km/h'), 'vMax 14.4 km/h')
  vMax = iv:new('vMax', -1/3, 'm/s')
  assertEquals(vMax:format('#is #v12.9f #us', nil), 'vMax -0.333333333 m/s')
  assertAlmostEquals(tonumber(vMax:format('#v.13g', nil)), vMax.value, 1e-12)
  assertAlmostEquals(tonumber(iv.c.mProton:format('#v.13g', nil)), iv.c.mProton.value, 1e-12)
end

function TestIntervals:test_toJson()
  local vMax = iv:new('vMax', 4, 'm/s')
  assertEquals(vMax:toJson(), '{ "type": "PhysValue", "id": "vMax", "value": 4, "unit": "m/s"}')
  assertEquals(vMax:toJson('km/h'), '{ "type": "PhysValue", "id": "vMax", "value": 14.4, "unit": "km/h"}')
  vMax = iv:new('vMax', -1/3, 'm/s')
  assertEquals(vMax:toJson('m/s'), '{ "type": "PhysValue", "id": "vMax", "value": -0.3333333333333, "unit": "m/s"}')
  assertEquals(iv.c.mProton:toJson(), '{ "type": "PhysValue", "id": "mProton", "value": 1.67492e-27, "unit": "kg"}')
  
end

--]]
lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
