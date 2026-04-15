export const CAMPAIGN_DESCRIPTION_SECTIONS = [
	{
		key: 'purpose',
		label: 'Mục đích chiến dịch',
		previewLabel: 'Mục đích',
		prefix: 'Chiến dịch này được tổ chức nhằm mục đích',
	},
	{
		key: 'problem',
		label: 'Vấn đề hoặc nhu cầu cần giải quyết',
		previewLabel: 'Vấn đề',
		prefix: 'Chiến dịch tập trung giải quyết vấn đề hoặc nhu cầu là',
	},
	{
		key: 'tasks',
		label: 'Công việc tình nguyện viên sẽ thực hiện',
		previewLabel: 'Công việc',
		prefix: 'Tình nguyện viên sẽ trực tiếp thực hiện các công việc như',
	},
	{
		key: 'commitment',
		label: 'Cam kết khi tham gia',
		previewLabel: 'Cam kết',
		prefix: 'Khi tham gia, tình nguyện viên cần cam kết',
	},
	{
		key: 'benefits',
		label: 'Quyền lợi hoặc hỗ trợ',
		previewLabel: 'Hỗ trợ',
		prefix: 'Quyền lợi hoặc hỗ trợ dành cho tình nguyện viên bao gồm',
	},
	{
		key: 'contact',
		label: 'Thông tin liên hệ phụ trách',
		previewLabel: 'Liên hệ',
		prefix: 'Thông tin liên hệ của người phụ trách chiến dịch là',
	},
];

function normalizeDescriptionText(description) {
	return String(description || '')
		.replace(/\r/g, ' ')
		.replace(/\n+/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();
}

function truncateText(text, maxLength = 160) {
	const normalized = String(text || '').trim();
	if (normalized.length <= maxLength) return normalized;
	return `${normalized.slice(0, Math.max(0, maxLength - 3)).trim()}...`;
}

export function extractCampaignDescriptionSections(description) {
	const text = normalizeDescriptionText(description);
	if (!text) return [];

	const matches = CAMPAIGN_DESCRIPTION_SECTIONS
		.map((section) => ({
			...section,
			index: text.indexOf(section.prefix),
		}))
		.filter((section) => section.index !== -1)
		.sort((a, b) => a.index - b.index);

	if (!matches.length) return [];
	if (matches.length === 1 && matches[0].index > 0) return [];

	return matches
		.map((section, index) => {
			const start = section.index + section.prefix.length;
			const end = index < matches.length - 1 ? matches[index + 1].index : text.length;
			const value = text
				.slice(start, end)
				.replace(/^[\s:;,.!-]+/, '')
				.replace(/[\s.]+$/, '')
				.trim();

			return value
				? {
					key: section.key,
					label: section.label,
					previewLabel: section.previewLabel,
					value,
				}
				: null;
		})
		.filter(Boolean);
}

export function parseCampaignDescription(description) {
	const sections = extractCampaignDescriptionSections(description);
	if (sections.length) {
		return sections.map((section) => section.value);
	}

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
	const sections = extractCampaignDescriptionSections(description);
	if (sections.length) {
		return truncateText(
			sections
				.slice(0, maxItems)
				.map((section) => `${section.previewLabel}: ${section.value}`)
				.join(' • '),
			180
		);
	}

	const items = parseCampaignDescription(description);
	if (!items.length) return '';

	return truncateText(items.slice(0, maxItems).join(' • '), 180);
}
