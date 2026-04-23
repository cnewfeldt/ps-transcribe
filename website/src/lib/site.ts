/**
 * Single source of truth for external URLs and requirement strings on the PS Transcribe site.
 * Future owner/repo renames become a one-line change here.
 *
 * DMG URL uses %20 because scripts/make_dmg.sh produces "dist/PS Transcribe.dmg" (with a space);
 * .github/workflows/release-dmg.yml line 140 confirms the URL-encoded form. A dashed
 * variant (PS + hyphen + Transcribe.dmg) will 404 -- do NOT change this back.
 *
 * macOS version: Package.swift declares `.macOS(.v26)`; the design mock's older min-version
 * copy (Sonoma-era) is factually wrong and is overridden here with the real minimum.
 */
export const SITE = {
  OWNER: 'cnewfeldt',
  REPO: 'ps-transcribe',
  REPO_URL: 'https://github.com/cnewfeldt/ps-transcribe',
  DMG_URL: 'https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg',
  APPCAST_URL: 'https://github.com/cnewfeldt/ps-transcribe/releases.atom',
  ISSUES_URL: 'https://github.com/cnewfeldt/ps-transcribe/issues/new',
  LICENSE_URL: 'https://github.com/cnewfeldt/ps-transcribe/blob/main/LICENSE',
  ACKNOWLEDGEMENTS_URL: 'https://github.com/cnewfeldt/ps-transcribe#acknowledgments',
  OS_REQUIREMENTS: 'macOS 26+ · Apple Silicon · Free & open source',
  OS_REQUIREMENTS_FINAL_CTA: 'Free · Open source · macOS 26+ (Apple Silicon)',
} as const
