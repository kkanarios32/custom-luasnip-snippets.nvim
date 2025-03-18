M = {}

MATH_NODES = {
	display_math = true,
	inline_math = true,
}

LIST_NODES = {
	ul = true,
	ol = true,
}

M.in_mathzone = function()
	local node = vim.treesitter.get_node({ ignore_injections = false })
	while node do
		if MATH_NODES[node:type()] then
			return true
		end
		node = node:parent()
	end
	return false
end

M.not_in_mathzone = function()
	return not M.in_mathzone()
end

M.in_list = function()
	local node = vim.treesitter.get_node({ ignore_injections = false })
	while node do
		if LIST_NODES[node:type()] then
			return true
		end
		node = node:parent()
	end
	return false
end

return M
