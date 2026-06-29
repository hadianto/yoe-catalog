-- Shared.lua
-- ModuleScript under ReplicatedStorage, named "Shared"
local Shared = {}

Shared.GAME_NAME = "Yoe Catalog" -- CHANGE ONCE. Renaming later orphans all save data.
Shared.DATA_VERSION = 1
-- in Shared.lua
Shared.ADMIN_IDS = { 9039786969, 9835488686 } -- REPLACE both with your two real UserIds (yours + alt/partner)

-- ===== THEME: edit these values to recolor the entire game in one place =====
Shared.THEME = {
	accentA    = Color3.fromRGB(198, 104, 72),  -- terracotta, primary buttons
	accentB    = Color3.fromRGB(224, 134, 96),  -- lighter terracotta, gradient + hover
	accentEdge = Color3.fromRGB(236, 158, 120), -- stroke on accent buttons

	panelBg    = Color3.fromRGB(28, 25, 22),     -- warm near-black panel body
	panel2     = Color3.fromRGB(40, 35, 31),     -- panel gradient top
	cardBg     = Color3.fromRGB(44, 39, 34),     -- ticket row
	cardPaid   = Color3.fromRGB(34, 44, 36),     -- paid row, faint green tint
	field      = Color3.fromRGB(40, 35, 31),     -- input box

	stroke     = Color3.fromRGB(92, 80, 70),     -- warm borders
	textMain   = Color3.fromRGB(245, 240, 234),
	textSub    = Color3.fromRGB(190, 178, 168),
	textSubHex = "#beb2a8",                       -- same as textSub, for RichText

	successA   = Color3.fromRGB(70, 168, 108),   -- confirm / paid (kept green = safe)
	successB   = Color3.fromRGB(96, 196, 132),
	warn       = Color3.fromRGB(226, 162, 70),   -- outstanding pill
	neutral    = Color3.fromRGB(82, 74, 66),     -- cancel button
	idle       = Color3.fromRGB(56, 50, 44),     -- inactive filter tab
}
Shared.DEFAULT_PROFILE = {
	Purchases = {
		PlusConversions = 0,
		PlusLastConvertedAt = 0,
		DevProductSpend = 0,      -- exact Robux, from receipts
		DevProductCount = 0,
		GamepassCount = 0,
		CatalogSpend = 0,         -- player spend on catalog, full robux
		BundleSpend = 0,          -- player spend on bundles, full robux
		RefundClaimedSpend = 0,   -- catalog+bundle spend already turned into a ticket, prevents double-claim
		ReceiptIds = {},          -- dedupe ProcessReceipt re-calls
		History = {},             -- rolling log of recent purchases
	},
}

function Shared.formatNumber(value: number): string
	if value >= 1_000_000_000_000 then
		return string.format("%.1fT", value / 1_000_000_000_000)
	end
	if value >= 1_000_000_000 then
		return string.format("%.1fB", value / 1_000_000_000)
	end
	if value >= 1_000_000 then
		return string.format("%.1fM", value / 1_000_000)
	end
	if value >= 1_000 then
		return string.format("%.1fK", value / 1_000)
	end
	return tostring(math.floor(value))
end

return Shared