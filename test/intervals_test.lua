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
  
  -- Initialize with an interval
  b = iv:new(a)
  assertEquals(b.value, a.value)
  assertEquals(b.low, a.low)
  assertEquals(b.high, a.high)
  
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
  

function TestIntervals:test_sqrt()
  local a = iv:new({l=9,v=16,h=25})
  local b = iv:new({l=-9.5,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  
  
  local c
  
  c = a:sqrt()
  assertEquals(c.value, 4)
  assertEquals(c.low,3)
  assertEquals(c.high,5)
 
 
  c = a*a
  c = c:sqrt()
  assertEquals(a==c, true)
  
  local function _sqrt(v) return v:sqrt(); end
  
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_sqrt, b)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_sqrt, d)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  
end

function TestIntervals:test_cbrt()
  local a = iv:new({l=27, v=64, h=125})
  local b = iv:new({l=-0.01,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  
  
  local c
  
  c = a:cbrt()
  assertAlmostEquals(c.value, 4, 1e-12)
  assertAlmostEquals(c.low, 3,1e-12)
  assertAlmostEquals(c.high, 5,1e-12)
  
 
  c = a*a*a
  c = iv.cbrt(c)
  assertAlmostEquals(c.value, a.value, 1e-12)
  assertAlmostEquals(c.low, a.low,1e-12)
  assertAlmostEquals(c.high, a.high,1e-12)
  
  local function _cbrt(v) return v:cbrt(); end
  
  
  local ok, res
  -- Cubique root of negative number is not supported.
  ok, res = pcall(_cbrt, b)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  
  local ok, res
  -- Cubique root of negative number is not supported.
  ok, res = pcall(_cbrt, d)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  
end

function TestIntervals:test_pow()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new({l=-0.01,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  local z = iv:new(0)

  local function _pow(b,e) return b^e; end
  
  local c
  -- Interval powered by number
  c = a^2
  assertEquals(c.value, a.value*a.value)
  assertEquals(c.low,a.low*a.low)
  assertEquals(c.high,a.high*a.high)
  

  c = a^-2
  assertEquals(c.value, 1/(a.value*a.value))
  assertEquals(c.high, 1/(a.low*a.low))
  assertEquals(c.low, 1/(a.high*a.high))

  local ok, res
  -- power of null is not supported.
  ok, res = pcall(_pow, z, 2)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  -- power of non-positives is not supported
  ok, res = pcall(_pow, d, 2)
  assertFalse(ok)
  assertStrContains(res,'All base members must be positive')
  
  -- Number powered by interval  
  c = 2^a
  assertEquals(c.value, 2 ^ a.value)
  assertEquals(c.low, 2 ^ a.low)
  assertEquals(c.high, 2 ^ a.high)
  

  c = 2^-a
  assertEquals(c.value, 1/(2 ^ a.value))
  assertEquals(c.high, 1/(2 ^ a.low))
  assertEquals(c.low, 1/(2 ^ a.high))

  -- 1 powered by x is always 1
  c = 1 ^ b
  assertEquals(c.value, 1)
  assertEquals(c.high, 1)
  assertEquals(c.low, 1)
  
  -- power of zero is not supported
  ok, res = pcall(_pow, 0, a)
  assertFalse(ok)
  assertStrContains(res,'Base must be positive')
  
  -- power of negatives is not supported
  ok, res = pcall(_pow, -0.00001, a)
  assertFalse(ok)
  assertStrContains(res,'Base must be positive')
  
  -- Interval powered by interval
  c = a ^ b
  assertEquals(c.value, a.value ^ b.value)
  assertEquals(c.low, a.high ^ b.low) -- ATTENTION 4^-0.01 is less then 2^-0.01 !!
  assertEquals(c.high, a.high ^ b.high)
  
end
 
function TestIntervals:test_log()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv.log(a)
  
  assertEquals(b.value, math.log(a.value))
  assertEquals(b.low, math.log(a.low))
  assertEquals(b.high, math.log(a.high))
end
  
function TestIntervals:test_log10()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv.log10(a)
  
  assertEquals(b.value, math.log10(a.value))
  assertEquals(b.low, math.log10(a.low))
  assertEquals(b.high, math.log10(a.high))
end
  
function TestIntervals:test_eq()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new({l=-0.01,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  local z = iv:new(0)
  
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
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new({l=-0.01,v=10,h=10.3})
  local d = iv:new{l=-11, v=-10, h =-9}
  local e = iv:new{l=1, v=1.5, h=2-1e-12}
  local z = iv:new(0)
  
  local c = a
  assertEquals(a<a, false)
  assertEquals(a>a, false)
  assertEquals(c<a, false)
  assertEquals(c>a, false)

  assertEquals(e<a, true)
  assertEquals(a>e, true)
  assertEquals(e>a, false)
  assertEquals(a<e, false)
  
end

function TestIntervals:test_le()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new{l=2-1e-12, v=3, h=4}
  local d = iv:new{l=2+1e-12, v=3, h=4-1e-12}
  local c = a
  assertEquals(a<=a, true)
  assertEquals(a>=a, true)
  assertEquals(c<=a, true)
  assertEquals(c>=a, true)
  
  assertEquals(b<=a, true)
  assertEquals(a>=b, true)
  assertEquals(a<=b, false)
  assertEquals(b>=a, false)

  -- d is included in a / both directions false
  assertEquals(d<=a, false)
  assertEquals(a<=d, false)
  assertEquals(d>=a, false)
  assertEquals(a>=d, false)
    
end

function TestIntervals:test_includes()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new{l=2-1e-12, v=3, h=4}
  local d = iv:new{l=2+1e-12, v=3, h=4-1e-12}
  local c = a
  -- inclusion of intervals
  assertEquals(a:includes(a), true)
  assertEquals(a:includes(c), true)
  assertEquals(c:includes(a), true)
  assertEquals(c:includes(c), true)
  
  assertEquals(b:includes(a), true)
  assertEquals(a:includes(b), false)
  assertEquals(d:includes(a), false)
  assertEquals(a:includes(d), true)

  -- inclusion of numbers
  assertEquals(a:includes(2), true)
  assertEquals(a:includes(4), true)
  assertEquals(a:includes(2-1e-12), false)
  assertEquals(a:includes(4+1e-12), false)
    
end

function TestIntervals:test_compare()
  local a = iv:new({l=2, v=3, h=4})
  local b = iv:new{l=2-1e-12, v=3, h=4}
  local c = iv:new{l=2+1e-12, v=3, h=4-1e-12}

  -- inclusion of intervals
  local i,v
  i,v = a:compare(a)
  assertEquals({i,v}, {'==','=='})
  i,v = a:compare(b)
  assertEquals({i,v}, {'b[a]','=='})
  i,v = a:compare(c)
  assertEquals({i,v}, {'a[b]', '=='})
  
  -- Check different values
  i,v = a:compare(iv:new{l=2,v=3+1e-12,h=4})
  assertEquals({i,v}, {'==', '<'})
  i,v = a:compare(iv:new{l=2,v=3-1e-12,h=4})
  assertEquals({i,v}, {'==', '>'})
  
  -- Check interval for '>' and '>='
  i,v = a:compare(iv:new{l=0, v=1, h=2})
  assertEquals({i,v}, {'>=', '>'})
  i,v = a:compare(iv:new{l=0, v=1, h=2-1e-12})
  assertEquals({i,v}, {'>', '>'})

  -- Check interval for '<' and '<='
  i,v = a:compare(iv:new{l=4, v=5, h=6})
  assertEquals({i,v}, {'<=', '<'})
  i,v = a:compare(iv:new{l=4+1e-12, v=5, h=6})
  assertEquals({i,v}, {'<', '<'})
  
  -- Check with Numbers
  -- Check different values
  i,v = a:compare(2)
  assertEquals({i,v}, {'a[b]', '>'})
  i,v = a:compare(3)
  assertEquals({i,v}, {'a[b]', '=='})
  i,v = a:compare(4)
  assertEquals({i,v}, {'a[b]', '<'})
  
  -- Check value for '>' 
  i,v = a:compare(2-1e-12)
  assertEquals({i,v}, {'>', '>'})

  -- Check value for '<'
  i,v = a:compare(4+1e-12)
  assertEquals({i,v}, {'<', '<'})

end


function TestIntervals:test_tostring()
  local a = iv:new{v=10.1, d=0.5}
  local str = tostring(a):gsub(',','.') -- (adapt for all i18n modes)
  assertEquals(str, '10.1 [9.6; 10.6]')
end


function TestIntervals:test_format()
  local a = iv:new{v=10.1, d=0.5}
  assertEquals(a:format():gsub(',','.'), '10.1 [9.6; 10.6]')
  assertEquals(a:format('x=#mg; #lg <= x <= #hg'):gsub(',','.'), 'x=10.1; 9.6 <= x <= 10.6')
  local b = a/3
  assertEquals(b:format('x=#m4.2f; #l4.2f <= x <= #h4.2f'):gsub(',','.'), 'x=3.37; 3.20 <= x <= 3.53')
  assertAlmostEquals(tonumber(b:format('#m.13g', nil)), b.value, 1e-12)
end

function TestIntervals:test_toJson()
  local a = iv:new{v=10.1, d=0.5}
  assertEquals(a:toJson(), '{ "type": "Interval", "value": 10.1, "low": 9.6, "high": 10.6}')
end


lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
