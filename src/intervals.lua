-------------------------------------
-- Provides a class for interval arithmetics.
-- @module invervals

local class = require'middleclass'
local math = require('math')
------------------------------------- 
-- Holds the class structure of the module.
-- 
-- @type Interval  
local Interval = class('Interval')

-------------------------------------
-- Constructor: called in Interval.new().
-- @param value  table defining the interval or a number
-- @field value.v number of the value
-- @field value.l lower bound of interval
-- @field value.h upper bount of interval
-- @field value.d delta range around v (overwrites value.l and value.h)
-- @usage iv = Interval:new(10) -- low = high = value = 10
-- iv = Interval:new({v=10}) -- low = high = value = 10
-- iv = Interval:new(iv2) -- initialize with the interval iv2
-- iv = Interval:new({l=9,v=10,h=11}) -- low=9, value=10, high=11
-- iv = Interval:new({v=10,d=0.5}) -- low=9.5, value=10, high=10.5
function Interval:initialize(value)
  if type(value) == 'number' then
    self.value = value
    self.low = value
    self.high = value
  else
    assert(type(value) == 'table', 'Initializer must be a table or a number')
    self.value = value.v or value.value or 0
    if value.d then
      self.low = self.value - value.d
      self.high = self.value + value.d
    else
      self.low = value.l or value.low or self.value
      self.high = value.h or value.high or self.value
    end
    
    self:normalize()
  end
end

-------------------------------------
-- normalizes the values so that
-- low <= value <= high.
-- 
-- If the value value is not within the [low; high] range
-- the range will be adapted to the value value.
-- @return Normalized number
function Interval:normalize()
  if self.low > self.high then
    local low = self.low
    self.low = self.high
    self.high = low
  end
  if self.value < self.low then
    self.low = self.value
  end
  
  if self.value > self.high then
    self.high = self.value
  end
  
  return self
end

function Interval._min(t)
  local m
  for _,v in ipairs(t) do
    m = m or v
    if v < m then
      m = v
    end
  end
  return m
end

function Interval._max(t)
  local m
  for _,v in ipairs(t) do
    m = m or v
    if v > m then
      m = v
    end
  end
  return m
end

---------------------------------------
-- Helper function: deep copies a interval
-- object.
-- The function avoids deep copy of the members
-- metatable and class
-- @param a Interval to be copied
function Interval.deep_copy(a)
  if type(a) ~= 'table' then return a end
  local copy = {}
  local m = getmetatable(a)
  for k,v in pairs(a) do
    if k ~= 'metatable' and k ~= 'class' then
      copy[k] = deep_copy(v)
    else
      copy[k] = v
    end
  end
  setmetatable(copy,m)
  return copy  
end

function deep_copy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen an copy recursively.
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.deep_copy(k, s)] = table.deep_copy(v, s) end
  return res
end

-------------------------------------
-- Add b to self.
-- @param b Interval ( or number) to be added
-- @return #Interval Sum of self and b. 
-- @usage iv1 = iv2 + iv3
function Interval:__add(b)
  local a = Interval.deep_copy(self)
  local c = Interval.deep_copy(b)
  if type(c) == 'number' then
    a.value = a.value + c
    a.low = a.low + c
    a.high = a.high + c
  elseif type(a) == 'number' then
    c.value = c.value + a
    c.low = c.low + a
    c.high = c.high + a
    a = c 
  else
    a.value = a.value + c.value
    a.low = a.low + c.low
    a.high = a.high + c.high
  end
  return a:normalize()
end

-------------------------------------
-- Substract b from self.
-- @param b Interval to be subtracted
-- @return #Interval Difference of self and b. 
-- @usage iv1 = iv2 - iv3
function Interval:__sub(b)
  local a = Interval.deep_copy(self)
  local c = Interval.deep_copy(b)
  if type(c) == 'number' then
    a.value = a.value - c
    a.low = a.low - c
    a.high = a.high - c
  elseif type(a) == 'number' then
    c.value = a - c.value
    c.low = a - c.low
    c.high = a - c.high 
    a = c 
  else
    a.value = a.value - c.value
    a.low = a.low - c.high
    a.high = a.high - c.low
  end
  return a:normalize()
end

-------------------------------------
-- Unary minus of self.
-- @return #Interval Negative value of self.
-- @usage iv1 = -iv2
function Interval:__unm()
  return 0 - self
end

-------------------------------------
-- Multiply self by b.
-- @param b Multiplicator (can be Interval or number)
-- @return #Interval self * b 
-- @usage iv1 = iv2 * iv3
--iv1 = iv2 * number3
function Interval:__mul(b)
  local a = Interval.deep_copy(self)
  local c = Interval.deep_copy(b)
  if type(c) == 'number' then
    a.value = a.value * c
    a.low = a.low * c
    a.high = a.high * c
  elseif type(a) == 'number' then
    c.value = c.value * a
    c.low = c.low * a
    c.high = c.high * a
    a = c 
  else
    a.value = a.value * c.value
    local values = {a.low * c.low, a.low * c.high, a.high * c.low, a.high * c.high}
    a.low = Interval._min(values)
    a.high = Interval._max(values)
  end
  return a:normalize()
end

-------------------------------------
-- Divide by b
-- @param b Divisor (can be #Interval or #number)
-- @return #Interval self / b 
-- @usage iv1 = iv2 / iv3
--iv1 = iv2 / number3
function Interval:__div(b)
  local a
  if type(b) == 'number' then
    a = Interval.deep_copy(self)
    a.value = a.value / b
    a.low = a.low / b
    a.high = a.high / b
    return a:normalize()
  end

  if type(self) == 'number' then
    a = Interval:new({v=self})
  else
    a = Interval.deep_copy(self)
  end
  
  if b.high * b.low > 0 then
    return a * Interval:new{l=1/b.high, v=1/b.value, h=1/b.low}
  else
    a.value = a.value / b.value
    a.low = - math.huge
    a.high = math.huge
  end
  return a:normalize()
end

-------------------------------------
-- Power(b)
-- @param b Exponent (a #number)
-- @return #Interval self ^ b 
-- @usage iv1 = iv2 ^ 2
-- iv1 = 2 ^ iv2
-- iv1 = iv2 ^ iv3
function Interval:__pow(b)
  if type(self) == 'number' then
    assert(self > 0, "Base must be positive: " .. tostring(self))
    return Interval:new{l=self^b.low, v=self^b.value, h=self^b.high}
  else
    assert(self.low > 0, "All base members must be positive: " .. tostring(self))
    if type(b) == 'number' then
      local a = Interval.deep_copy(self)
      a.low = a.low ^ b
      a.value = a.value ^ b
      a.high = a.high ^ b
      return a:normalize()
    else
      local a = Interval.deep_copy(self)
      a.value = a.value ^ b.value
      local v = {a.low ^ b.low, a.low ^ b.high, a.high ^ b.low, a.high ^ b.high}
      a.low = Interval._min(v)
      a.high = Interval._max(v)
      return a:normalize()
    end
  end
end

-------------------------------------
-- Square root
-- @return #Interval self ^ (1/2) 
-- @usage iv1 = iv2:sqrt()
function Interval:sqrt()
  if self == Interval:new(0) then return self end
  return self ^ 0.5
end

-------------------------------------
-- Cubic root
-- @return #Interval self ^ (1/3) 
-- @usage iv1 = iv2:cbrt()
function Interval:cbrt()
  if self == Interval:new(0) then return self end
  return self ^ (1/3)
end

-------------------------------------
-- Decimal logarithmus (base 10).
-- @param self: The argument of log10 function
-- @return #Interval: decimal logarithmus of a
-- @usage iv1 = Interval.log10(a)
-- iv1 = iv2:log10()
function Interval:log10()
  assert(self.low > 0, "All interval members must be positive: " .. tostring(self))
  return Interval:new{l=math.log10(self.low), v=math.log10(self.value), h=math.log10(self.high)}
end

-------------------------------------
-- Natural logarithmus (base e).
-- @param self: The argument of log function
-- @return #Interval: decimal logarithmus of a
-- @usage iv1 = Interval.log(a)
-- iv1 = iv2:log()
function Interval:log()
  assert(self.low > 0, "All interval members must be positive: " .. tostring(self))
  return Interval:new{l=math.log(self.low), v=math.log(self.value), h=math.log(self.high)}
end

-------------------------------------
-- Compare Equal self '==' b.
-- Intervals are equal if low, high and value of both operands match.
-- @param b #Interval to be compared
-- @return true if self == b
-- @usage if iv1 == iv2 then ...
function Interval:__eq(b)
  return self.low == b.low and self.value == b.value and self.high == b.high
end

-------------------------------------
-- Compare less than self '<' b.
-- Intervals iv1 is assumed to be less than interval iv2 only if the two 
-- intervals have no intersection, i.e. iv1.high < iv2.low
-- @param b #Interval to be compared
-- @return true if self < b
-- @usage if iv1 < iv2 then ...
--if iv1 > iv2 then ...
function Interval:__lt(b)
  return self.high < b.low
end

-------------------------------------
-- Compare Less equal(b) '<='.
-- The definition of 'less or equal' follows the definition provided by Bohlender, Kulisch and Lohner 2008.
-- Take two intervals A = [a1,a2] and B = [b1,b2]. A is said to be less or equal B if
-- A <= B : a1 <= b1 and a2 <= b2
-- To say explicit: A <= B is totally different from (A < B or A == B) !
-- @param b  #Interval to be compared
-- @return true if self <= b
-- @usage if iv1 <= iv2 then ...
--if iv1 >= iv2 then ...
function Interval:__le(b)
  return self.low <= b.low and self.high <= b.high
end

-------------------------------------
-- Check inclusion.
-- Checks if a value or an interval is fully included in self
-- @param b  #Interval or number to be checked
-- @return true if all values of b are member of self
-- @usage if iv1:includes(iv2) then ...
-- if iv1:includes(3.1) then ...
function Interval:includes(b)
  if type(b) == 'number' then
    return self.low <= b and b <= self.high
  else
    return self.low <= b.low and b.high <= self.high
  end
end

-------------------------------------
-- Compare intervals.
-- Compares the relation between self (a) and another interval/value (b)
-- @param b #Interval or b #number to be checked
-- @return #string i, #string v
-- first string reflects the relation of the intervals:
-- <ul>
-- <li>'<' if a is less than b</li>
-- <li>'==' if intervals are equal</li>
-- <li>'a[b]' if b is fully included in a</li>
-- <li>'b[a]' if a is included in b</li>
-- <li>'<=' if a and b have common elements and a.low <= b.low</li>
-- <li>'=>' if a and b have common elements and a.high >= b.high</li>
-- <li>'>' if a is greater than b</li>
-- <li>'?' in any other case (would be an implementation fault)</li>
-- </ul>
-- The second string reflects the relation of the values:
-- <ul>
-- <li>'<' a.value < b.value</li>
-- <li>'==' if a.value == b.value</li>
-- <li>'>' a.value > b.value</li>
-- </ul>
function Interval:compare(b)
  if type(b) == 'number' then
    b = Interval:new(b) --newbee, haha
  end
  if self == b then 
    return '==', '==' 
  end
  
  local vres = '?'
  if self.value < b.value then 
    vres = '<'
  elseif self.value == b.value then
    vres = '=='
  else
    vres = '>'
  end
  
  local ires = '?'
  if self.high < b.low then
    ires = '<'
  elseif self.low == b.low and self.high == b.high then
    ires = '=='
  elseif self.low >= b.low and self.high <= b.high then
    ires = 'b[a]'
  elseif b.low >= self.low and b.high <= self.high then
    ires = 'a[b]'
  elseif self.high <= b.high then
    ires = '<='
  elseif self.low > b.high then
    ires = '>'
  elseif self.low >= b.low then
    ires = '>='
  end
  return ires, vres 
end

-------------------------------------
-- String conversion.
-- Converts the Interval to a string
-- This function calls Interval:format
-- with the standard format.
-- @return String representation of the Interval
-- @usage a = Interval:new{l=9,v=10,h=10.4}
-- tostring(a)
--   returns '10 [9; 10.4]'
function Interval:__tostring()
  return self:format()
end

-------------------------------------
-- String format. 
-- Formats the Interval to a string with a given format
-- and unit.
-- @param f Format string.
-- In the format string can be the following tokens that
-- are substituted by the fields of the Interval:
-- <ul>
-- <li> '#m'  Middle, substituted by self.value </li>
-- <li> '#l'  Low, substituted by self.low</li>
-- <li> '#h'  High, substituted by self.high</li>
-- </ul>
-- all tokens will be replaced by a '%' character so that
-- the following characters define the format string for 
-- the string.format() function.
-- So the format string '#m5.1f [#l5.1f,#h5.1f]' will do the same like
-- string.format('%5.1f [%5.1f,%5.1f]', iv.value, iv.low, iv.high)
-- @return String according to given format.
-- @usage a = Interval:new{l=1.5,v=2,h=2.5}
-- a:format('Result: #m5.1f [#lf,#hf]')
--   gives 'Result:   2.0 [1.5,2.5]'
function Interval:format(f)
  f = f or "#mg [#lg; #hg]"
  local value = self.value
  local str

  str = string.gsub(f,"#m","%%")
  str = string.format(str,self.value)
  str = string.gsub(str,"#l","%%")
  str = string.format(str,self.low)
  str = string.gsub(str,"#h","%%")
  str = string.format(str,self.high)
  return str
end

-------------------------------------
-- Generate JSon string. 
-- Converts the Interval to a Json string.
-- The point '.' is always used for decimals in numbers.
-- @return A Json string.
-- @usage Interval:new({v=10,d=0.5}):toJSon()
-- will return e.g. '{ "type": "Interval", "value": 10 , "low": 9.5 , "high": 10.5 }'
function Interval:toJson()
  return '{"type": "Interval", "value": ' .. self:format('#m.13g'):gsub(',','.')
          .. ' , "low": ' .. self:format('#l.13g'):gsub(',','.')
          .. ' , "high": ' .. self:format('#h.13g'):gsub(',','.')
          .. ' }'
end

return Interval
