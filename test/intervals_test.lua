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

--[[
function TestIntervals:test_add()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 12, 'mm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function add(a,b) return a+b; end
  
  local ok, res, c
  
  c = a+b
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b+a
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  ok, res = pcall(add,b*b,a)
  assertFalse(ok)
  assertStrContains(res, 'Unmatching unit in add/sub')
  ok,res = pcall(add, 1, a)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
  ok,res = pcall(add, a, 5)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
end


function TestIntervals:test_sub()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 12, 'mm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function sub(a,b) return a+b; end
  
  local ok, res, c
  
  c = a-b
  assertEquals(c.value, 100-0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b-a
  assertEquals(c.value, 0.012-100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  ok, res = pcall(sub,b*b,a)
  assertFalse(ok)
  assertStrContains(res, 'Unmatching unit in add/sub')
  ok, res = pcall(sub, 1, a)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
  ok, res = pcall(sub, a, 5)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
end
  
function TestIntervals:test_unm()
  local a = iv:new('a', 100, 'm')
  
 
  local c
  
  c = -a
  assertEquals(c.value, -100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = - -a
  assertEquals(c.value, 100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')
  
end
 
function TestIntervals:test_mul()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 12, 'ms')
  local s = iv:new('s', 12, 'm/s')
  
  local c
  
  c = a*b
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  

  c = b*a
  assertEquals(c.value, 0.012*100)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  
  -- Multiplying with number keeps the symbol
  c = 0.012*a
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')

  c = a*0.012
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')
  
  -- Multiplying speed [m/s] with time [s] should remove the member units.s 
  c = s * b
  assertEquals(c.value, 12*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,nil)
end
  
function TestIntervals:test_div()
  local a = iv:new('a', 100, 'm')
  local b = iv:new('b', 12, 'ms')
  local s = iv:new('s', 12, 'm/s')
  
  local c
  
  c = a/b
  assertAlmostEquals(c.value, 100/0.012, 1e-12)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,-1)
  assertEquals(c.symbol,nil)
  

  c = b/a
  assertEquals(c.value, 0.012/100)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  
  -- Dividing by number keeps the symbol
  c = a / 0.012
  assertAlmostEquals(c.value, 100/0.012, 1e-12)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')

  c = 0.012 / a
  assertEquals(c.value, 0.012/100)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,nil)
  
  -- Dividing speed [m/s] by length [m] should remove the member units.m 
  c = s / a
  assertEquals(c.value, 12/100)
  assertEquals(c.units.m,nil)
  assertEquals(c.units.s,-1)
  assertEquals(c.symbol,nil)
  
  -- Dividing by zero return math.huge
  c = a / 0
  assertEquals(c.value, math.huge)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')
 
end
  
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

function TestIntervals:test_getBaseUnitString()
  local s = iv.u['N']:_getBaseUnitString()
  -- The resulting string does not guarantee the sequence of
  -- base units. So we have to check for any possible sequence.
  assertStrContains(s,"kg")
  assertStrContains(s,"m")
  assertStrContains(s,"s^-2")
  
  s=s:gsub('kg','',1)
  s=s:gsub('m','',1)
  s=s:gsub('s%^%-2','',1)
  
  assertStrMatches(s,'**')
end

function TestIntervals:test_getUnitFactor()
  assertEquals(iv.u['mm']:_getUnitFactor('mm'), 0.001)
  assertEquals(iv.u['mm']:_getUnitFactor(), 0.001)
  local a = iv.u['m'] / iv.u['s']
  assertEquals(a:_getUnitFactor('km/h'), 1/3.6)
  
  local function getUnitFactor(p,unit) return p:_getUnitFactor(unit); end
  
  local ok, res
  
  ok, res = pcall(getUnitFactor, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(getUnitFactor, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(getUnitFactor, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
end

function TestIntervals:test_getValue()
  assertEquals(iv.u['mm']:getValue('km'), 1e-6)
  local a = iv.u['m'] / iv.u['s']
  assertAlmostEquals(a:getValue('km/h'), 3.6, 1e-12)
  
  local function getValue(p,unit) return p:getValue(unit); end
  
  local ok, res
  
  ok, res = pcall(getValue, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(getValue, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(getValue, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
end

function TestIntervals:test_setPrefUnit()
  local a = iv.u['km'] / iv.u['h']
  a:setPrefUnit('m/s')
  assertEquals(a.symbol,'m/s')
  local function setPrefUnit(p,unit) return p:setPrefUnit(unit); end
  
  local ok, res
  
  ok, res = pcall(setPrefUnit, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(setPrefUnit, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(setPrefUnit, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
  
  
end

function TestIntervals:test_concat()
  local a = iv.u['m'] / iv.u['s']
  a:setPrefUnit('m/s')
  assertStrMatches((2*a)..'km/h','7.2 km/h')
  assertStrMatches('Speed: '..a, 'Speed: 1 m/s')
  
  local function concat(p,unit) return p..unit; end
  
  local ok, res
  
  ok, res = pcall(concat, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(concat, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')

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

function TestIntervals:test_setId()
  local vMax = iv:new('vMax', 4, 'm/s')
  assertEquals(vMax:format('#is #vg #us', nil), 'vMax 4 m/s')
  assertEquals(vMax:setId('vMin'):format('#is #vg #us', nil), 'vMin 4 m/s')
end
--]]
lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
