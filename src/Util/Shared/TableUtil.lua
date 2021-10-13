-- angrybino
-- TableUtil
-- September 30, 2021

--[[
    TableUtil.DeepCopyTable(tabl : table) --> table [DeepCopiedTable]
    TableUtil.ShallowCopyTable(tabl : table) --> table [ShallowCopiedTable]
    TableUtil.ReconcileTable(tabl : table, templateTable : table) --> table [ReconciledTable]
    TableUtil.ShuffleTable(tabl : table, randomObject : Random | nil) --> table [ShuffledTable]
    TableUtil.SyncTable(tabl : table, templateSyncTable  : table) --> table [SyncedTable]
    TableUtil.IsTableEmpty(tabl : table) --> boolean [IsTableEmpty]
    TableUtil.Map(tabl : table, callback : function) --> table [MappedTable]
	TableUtil.DeepFreezeTable(tabl : table) --> void []
	TableUtil.ConvertTableIndicesToStartFrom(tabl : table, index : number) --> tabl []
]]

local TableUtil = {}

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

function TableUtil.DeepFreezeTable(tabl)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.DeepFreezeTable()", "table", typeof(tabl))
	)

	table.freeze(tabl)

	for key, value in pairs(tabl) do
		if typeof(value) == "table" and not table.isFrozen(value) then
			TableUtil.DeepFreezeTable(value)
		end

		if typeof(key) == "table" and not table.isFrozen(key) then
			TableUtil.DeepFreezeTable(key)
		end
	end
end

function TableUtil.DeepCopyTable(tabl, _cache)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.DeepCopyTable()", "table", typeof(tabl))
	)

	_cache = _cache or {
		[tabl] = true,
	}
	local deepCopiedTable = {}

	for key, value in pairs(tabl) do
		if typeof(value) == "table" and not _cache[value] then
			_cache[value] = true
			deepCopiedTable[key] = TableUtil.DeepCopyTable(value, _cache)
		end

		if not deepCopiedTable[key] then
			deepCopiedTable[key] = value
		end
	end

	return deepCopiedTable
end

function TableUtil.ShallowCopyTable(tabl)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.ShallowCopyTable()", "table", typeof(tabl))
	)

	local copiedTable = {}

	for key, value in pairs(tabl) do
		copiedTable[key] = value
	end

	return copiedTable
end

function TableUtil.ReconcileTable(tabl, templateTable)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.ReconcileTable()", "table", typeof(tabl))
	)

	assert(
		typeof(templateTable) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"TableUtil.ReconcileTable()",
			"table",
			typeof(templateTable)
		)
	)

	for key, value in pairs(templateTable) do
		if not tabl[key] then
			if typeof(value) == "table" then
				tabl[key] = TableUtil.DeepCopyTable(value)
			else
				tabl[key] = value
			end
		end
	end

	setmetatable(tabl, templateTable)

	return tabl
end

function TableUtil.ShuffleTable(tabl, randomObject)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.ShuffleTable()", "table", typeof(tabl))
	)

	if randomObject then
		assert(
			typeof(randomObject) == "Random",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"TableUtil.ShuffleTable()",
				"Random object or nil",
				typeof(randomObject)
			)
		)
	end

	local random = randomObject or Random.new()

	for index = #tabl, 2, -1 do
		local randomIndex = random:NextInteger(1, index)
		-- Set the value of the current index to a value of a random index in the table, and set the value of the
		-- random index to the current value:
		tabl[index], tabl[randomIndex] = tabl[randomIndex], tabl[index]
	end

	return tabl
end

function TableUtil.IsTableEmpty(tabl)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.IsTableEmpty()", "table", typeof(tabl))
	)

	return not next(tabl)
end

function TableUtil.SyncTable(tabl, templateSyncTable, _cache)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.SyncTable()", "table", typeof(tabl))
	)

	assert(
		typeof(templateSyncTable) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"TableUtil.SyncTable()",
			"table",
			typeof(templateSyncTable)
		)
	)

	_cache = _cache or {
		[tabl] = true,
	}

	for key, value in pairs(tabl) do
		local templateValue = templateSyncTable[key]

		if not templateValue then
			tabl[key] = nil
		elseif typeof(value) ~= typeof(templateValue) then
			if typeof(templateValue) == "table" then
				tabl[key] = TableUtil.DeepCopyTable(templateValue)
			else
				tabl[key] = templateValue
			end
		elseif typeof(value) == "table" and not _cache[value] then
			_cache[value] = true
			tabl[key] = TableUtil.SyncTable(value, templateValue, _cache)
		end
	end

	for key, template in pairs(templateSyncTable) do
		local value = tabl[key]

		if not value then
			if typeof(template) == "table" then
				tabl[key] = TableUtil.DeepCopyTable(template)
			else
				tabl[key] = template
			end
		end
	end

	return tabl
end

function TableUtil.Map(tabl, callback)
	assert(
		typeof(tabl) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "TableUtil.Map()", "table", typeof(tabl))
	)

	assert(
		typeof(callback) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "TableUtil.Map()", "function", typeof(callback))
	)

	for key, value in pairs(tabl) do
		tabl[key] = callback(key, value, tabl)
	end

	return tabl
end

function TableUtil.ConvertTableIndicesToStartFrom(tabl, index, cache)
	cache = cache or {[tabl] = true}
	local currentIndex = index - 1
 
	for key, value in pairs(tabl) do
		if typeof(value) == "table" and not cache[value] then
			cache[value] = true
			TableUtil.ConvertTableIndicesToStartFrom(tabl, index, cache)
		end
 
		if typeof(key) == "table" and not cache[key] then
			cache[key] = true
			TableUtil.ConvertTableIndicesToStartFrom(tabl, index, cache)
		end

		if typeof(key) ~= "number" then
			continue
		end

		currentIndex += 1
		tabl[key] = nil
		tabl[currentIndex] = value
	end
	
	return tabl
end

return TableUtil
