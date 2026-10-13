vim.opt.runtimepath:prepend(arg[1])
vim.g.mkdp_auto_close = 0
vim.g.mkdp_browserfunc = "MkdpTestOpen"
vim.cmd([[
  function! MkdpTestOpen(url)
    let g:mkdp_test_url = a:url
  endfunction
]])
vim.cmd.runtime("plugin/mkdp.vim")

assert(vim.fn["mkdp#util#server_ready"]() == 1)
vim.fn["mkdp#util#install"]()
dofile(arg[1] .. "/build.lua")

vim.cmd.edit("preview.md")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Packaged preview" })
for _, command in ipairs({ "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" }) do
	assert(vim.fn.exists(":" .. command) == 2, command .. " is missing")
end

vim.cmd.MarkdownPreviewToggle()
assert(
	vim.wait(10000, function()
		return vim.g.mkdp_test_url ~= nil
	end),
	"The preview did not open"
)
local response = vim.system({ "curl", "--fail", "--silent", vim.g.mkdp_test_url }):wait()
assert(response.code == 0, response.stderr)
assert(response.stdout:find("<html", 1, true), "The embedded preview page was not served")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Refreshed preview" })
vim.cmd.doautocmd("CursorMoved")
vim.cmd.enew({ bang = true })
vim.bo.filetype = "markdown"
assert(vim.fn["mkdp#rpc#get_server_status"]() == 1, "Switching buffers stopped the preview")

vim.cmd.MarkdownPreviewStop()
assert(
	vim.wait(10000, function()
		return vim.fn["mkdp#rpc#get_server_status"]() == -1
	end),
	"The preview server did not stop"
)
