

--[[
    Stack
    
    A basic stack with push/pop, but with some specialization
    typically used in stack based languages.

    In the case of fonts, it can make processing Postscript
    fonts easier.
--]]
local Stack = {}
setmetatable(Stack,{
	__call = function(self, ...)
		return self:new(...);
	end,
});

local Stack_mt = {
	__len = function(self)
		return self:length()
	end,

	__index = Stack;
}

function Stack.new(self, obj)
	obj = obj or {first=1, last=0}

	setmetatable(obj, Stack_mt);

	return obj;
end

function Stack.length(self)
	return self.last - self.first+1
end


--[[
    Operand stack operators

    Count the number of entries on top of the stack
    down to a 'mark'.  Do not include the 'mark' in
    the count.
]]
function Stack.countToMark(self, amark)
    amark = amark or "STACK:MARKER"
    local ct = 0

    for _, item in self:elements() do
        if item == amark then
            break
        end

        ct = ct + 1
    end

    return ct
end

-- pop all the items off the stack
function Stack.clear(self)
	local n = self:length()
	for i=1,n do 
		self:pop()
	end

	return self
end

function Stack.dup(self)
    if self:length() > 0 then
        self:push(self:top())
    end

    return self
end

-- exch
-- Same as: 2 1 roll
function Stack.exch(self)
    local a = self:pop()
    local b = self:pop()
    self:push(a)
    self:push(b)
end

--[[
    mark

    Push a marker on the stack.  If no specific
    mark is specified, the default string of
    'STACK:MARKER' is pushed.
]]
function Stack.mark(self, amark)
    amark = amark or "STACK:MARKER"
    self:push(amark)
    
    return amark
end

--[[
    push

    Push a single item onto the top of the stack.
    You can not push a 'nil' item onto the stack.  Instead,
    you must create some specified to be a nil value, like
    a string such as "STACK:NULL".
]]
function Stack.push(self, value)
	local last = self.last + 1
	self.last = last
	self[last] = value

	return self
end

--[[
    pushn

    Push a number of operands on the stack.

    stk:pushn(1,2,3,4,5,6,7)
]]

function Stack.pushn(self, ...)
    local n = select('#',...)
    for i=1,n do
        self:push(select(i,...))
    end
    
    return self
end

--[[
    pop

    Pop a single item off the top of the stack
    If no item is there, a 'nil' is returned
    with a 'stack underflow' error message.
]]
function Stack.pop(self)
	local last = self.last
	if self.first > last then
		return nil, "list is empty"
	end
	local value = self[last]
	self[last] = nil         -- to allow garbage collection
	self.last = last - 1

	return value
end

--[[
    popn

    Pop a number of items off the stack at once.  They will
    be returned in FIFO order.  That is, if you had performed
    the operations:
    stk:push(1)
    stk:push(2)
    stk:push(3)

    Then;
    stk:popn(3)

    will return:

    1, 2, 3

]]
function Stack.popn(self, n)
    local tmp = {}
    for i=1,n do
        tmp[n-i+1] = self:pop()
    end

    return unpack(tmp)
end

function Stack.copy(self, n)
    local sentinel = self.last

    for i=1,n do 
        self:push(self[sentinel-(n-i)])
    end

    return self
end

-- n is the number of items to consider
-- j is the number of positions to exchange
-- this is a brute force implementation which simply
-- does a single rotation as many times as is needed
-- a more direct approach would be to calculate the 
-- new position of each element and use swaps to put
-- them in place
function Stack.roll(self,n,j)
    
    if j > 0 then   -- roll the stack up (counter clockwise)
        for i=1,j do
            local tmp = self:top()

            for i=1,n-1 do
                local dst = self.last-(i-1)
                local src = self.last-i
                self[dst] = self[src]
            end

            self[self.last-n+1] = tmp
        end  --  outer loop
    elseif j < 0 then   -- roll the stack 'down' (clockwise)
        for i=1,math.abs(j) do
            local tmp = self[self.last-(n-1)]

            for i=1,n-1 do
                local dst = self.last-(n-1)+i-1
                local src = self.last-(n-1)+i
                self[dst] = self[src]
            end

            self[self.last] = tmp
        end  --  outer loop
    end

    return self
end

--[[
    top
    
    return what's at the top of the stack without
    popping it off.  This is essentially a 'peek'
    operation.
]]
function Stack.top(self)

	local last = self.last
	if self.first > last then
		return nil, "list is empty"
	end

	return self[last]
end

--[[
    nth

    Return the 'nth' item from the top of the
    stack.

    Similar to 'top', it does not affect the items
    on the stack.
--]]
function Stack.nth(self, n)
	if n < 0 then return nil end

	local last = self.last
	local idx = last - n
	if idx < self.first then return nil, 'beyond end of stack' end
	
	return self[idx]
end

--[[
    elements

    return non-destructive iterator of elements on
    the stack.

    Items returned from this iterator are in LIFO
    order, which is the oposite of what you get if
    you use popn.

    Also, this is an iterator, rather than a single
    call that returns multiple values.

    stk:push(1, 2, 3)
    for _, element in stk:elements() do
        print(element)
    end

    Will print:

    3
    2
    1

]]
function Stack.elements(self)
	local function gen(param, state)
		if param.first > state then
			return nil;
		end

		return state-1, param.data[state]
	end

	return gen, {first = self.first, data=self}, self.last
end

return Stack