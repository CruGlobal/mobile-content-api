# XML Content Spec: Focus Areas

Specialist lane (novel, not from the standard table). The XSD files in `public/xmlns/` define the
XML format for every GodTools tool: `manifest.xsd`, the tool types (`tract`, `lesson`, `article`,
`cyoa`, `meta`), the page types, and the shared `content`, `analytics`, `shareable`, `training`,
`web` and `publish` schemas. They are served live at `https://mobile-content-api.cru.org/xmlns/...`,
and app versions already in the field parse content written against them. `Package` builds the
published zip (pages, tips, attachments, `manifest.xml`) and pushes it to S3; `Xml::Manifest`,
`XmlUtil`, `Xml::Filterable` and `Xml::Translatable` build and transform that XML.

**Backward compatibility**

- Content written against today's schema must keep validating, and apps that shipped against an
  older schema must keep parsing new content
- Look for: a new required attribute or element (`use="required"`, `minOccurs` above 0) on an
  existing type; a removed element, attribute or enumeration value; a narrowed `simpleType`
  (pattern, length, enumeration) that existing content may break; a changed default. Prefer
  optional additions with the default written in `xs:documentation`, and mark old forms deprecated
  in the documentation (as the bold text style was) rather than removing them

**Namespaces and references**

- Each schema has its own namespace under `https://mobile-content-api.cru.org/xmlns/`. On the Ruby
  side, `XmlUtil::XMLNS_*` and `XmlUtil.xpath_namespace` hold the prefixes
- Look for: a namespace or prefix used in a Ruby XPath with no matching `XMLNS_*` constant and
  `xpath_namespace` entry; `xs:import` / `schemaLocation` paths that break when served from
  `public/xmlns/`; attribute groups or types copied between files instead of referenced
  (`<xs:attributeGroup ref="manifest:resourceChecksums" />`)

**Schema tests**

- Files in `schema_tests/<type>/valid/**` must pass `xmllint --schema`; files in
  `schema_tests/<type>/invalid/**` must fail it (`schema_tests/invalid.sh`). CI
  (`.github/workflows/xml-schema-validation.yml`, calling `validate-schema.yml`) runs manifest,
  content, cyoa, lesson, tract and training, and those jobs are required checks on `master`
- Look for: a schema change with no new valid case; a new constraint with no invalid case; an
  invalid case that fails for a different reason than its name says; a new schema type not wired
  into `xml-schema-validation.yml`

**Building the XML and the package**

- `Package#build_zip` uses rubyzip 3 (`Zip::File.open(path, create: true)`); file names come from
  `XmlUtil.sha256_hexdigest`; manifest `page`, `resource` and `tip` entries carry
  `checksum-sha256` and `size`. Nodes are created with
  `xml.document.create_element(name, xmlns: ns)` and attached with `add_child`
  (`XmlUtil.get_or_create_child`)
- Look for: manifest output that no longer validates against `manifest.xsd`; XPath written without
  the namespace map; resources referenced in XML (`Package::XPATH_RESOURCES`, `XPATH_TIPS`) that
  the package does not include; publish filtering (`publish:if-locale`, `publish:if-locale-not`)
  or translation (`i18n-id`) behavior changed without a spec in `spec/models/xml/` or
  `spec/package_spec.rb`

**Checklist**

- [ ] Every schema change is backward compatible, or the PR says which app versions it breaks
- [ ] Every new attribute, element or constraint has a valid and an invalid `schema_tests` case
- [ ] Ruby that emits or reads the changed XML is updated in the same PR, with specs
- [ ] `CLAUDE.md`'s "Content Spec / XML Schemas" section still lists the right files

### From PR history

- A schema change ships with the Ruby that emits it and with tests on both sides: optional
  attributes through a documented `attributeGroup`, at least one `schema_tests/<type>/valid/` case
  and one `invalid/` case per new constraint (#1988 added
  `resource_checksum_sha256_invalid_chars.xml` and `resource_checksum_sha256_invalid_length.xml`),
  and specs in `spec/models/xml/manifest_spec.rb` / `spec/package_spec.rb` for the generated XML.
  Flag schema edits missing either side.
  <!-- evidence: PR #1988 -->
- A change to nokogiri, rubyzip or aws-sdk-s3 (in `Gemfile.lock`, or in code that calls them)
  needs evidence that `Package` and `Xml::Manifest` output is unchanged: the same namespaces on
  moved nodes, the same zip entries, the same S3 upload. Flag bumps of those gems that offer no such
  check.
  <!-- evidence: PR #2052, #2040, #2042 -->
- The files under `public/xmlns/` are live, mutable namespace URLs, not digested assets. Flag
  far-future `Cache-Control` or `public_file_server.headers` settings that would cover them, and
  renames or moves of those files.
  <!-- evidence: PR #2018 -->
