export function parseCampaignDescription(description) {
	const text = String(description || '').replace(/\r/g, '').trim();
	if (!text) return [];

	const items = text
		.split('\n')
		.map((line) => line.trim())
		.filter(Boolean)
		.map((line) => line.replace(/^[-*•]\s*/, '').trim())
		.filter(Boolean);

	return items.length ? items : [text];
}

export function buildCampaignDescriptionPreview(description, maxItems = 2) {
	const items = parseCampaignDescription(description);
	if (!items.length) return '';

	const preview = items.slice(0, maxItems).join(' • ');
	return items.length > maxItems ? `${preview}...` : preview;
}
