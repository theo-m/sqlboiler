{{- $alias := .Aliases.Table .Table.Name -}}
{{- $orig_tbl_name := .Table.Name -}}

// {{$alias.UpSingular}} is an object representing the database table.
type {{$alias.UpSingular}} struct {
	{{- range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{- $orig_col_name := $column.Name -}}
	{{- range $column.Comment | splitLines -}} // {{ . }}
	{{end -}}
	{{if ignore $orig_tbl_name $orig_col_name $.TagIgnore -}}
	{{$colAlias}} {{$column.Type}} `{{generateIgnoreTags $.Tags}}boil:"{{$column.Name}}" json:"-" toml:"-" yaml:"-"`
	{{else if eq $.StructTagCasing "title" -}}
	{{$colAlias}} {{$column.Type}} `{{generateTags $.Tags $column.Name}}boil:"{{$column.Name}}" json:"{{$column.Name | titleCase}}{{if $column.Nullable}},omitempty{{end}}" toml:"{{$column.Name | titleCase}}" yaml:"{{$column.Name | titleCase}}{{if $column.Nullable}},omitempty{{end}}"`
	{{else if eq $.StructTagCasing "camel" -}}
	{{$colAlias}} {{$column.Type}} `{{generateTags $.Tags $column.Name}}boil:"{{$column.Name}}" json:"{{$column.Name | camelCase}}{{if $column.Nullable}},omitempty{{end}}" toml:"{{$column.Name | camelCase}}" yaml:"{{$column.Name | camelCase}}{{if $column.Nullable}},omitempty{{end}}"`
	{{else if eq $.StructTagCasing "alias" -}}
	{{$colAlias}} {{$column.Type}} `{{generateTags $.Tags $colAlias}}boil:"{{$column.Name}}" json:"{{$colAlias}}{{if $column.Nullable}},omitempty{{end}}" toml:"{{$colAlias}}" yaml:"{{$colAlias}}{{if $column.Nullable}},omitempty{{end}}"`
	{{else -}}
	{{$colAlias}} {{$column.Type}} `{{generateTags $.Tags $column.Name}}boil:"{{$column.Name}}" json:"{{$column.Name}}{{if $column.Nullable}},omitempty{{end}}" toml:"{{$column.Name}}" yaml:"{{$column.Name}}{{if $column.Nullable}},omitempty{{end}}"`
	{{end -}}
	{{end -}}
	{{- if .Table.IsJoinTable -}}
	{{- else}}
	R *{{$alias.DownSingular}}R `{{generateTags $.Tags $.RelationTag}}boil:"{{$.RelationTag}}" json:"{{$.RelationTag}}" toml:"{{$.RelationTag}}" yaml:"{{$.RelationTag}}"`
	L {{$alias.DownSingular}}L `{{generateIgnoreTags $.Tags}}boil:"-" json:"-" toml:"-" yaml:"-"`
	{{end -}}
}

var {{$alias.UpSingular}}Columns = struct {
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}} string
	{{end -}}
}{
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}}: "{{$column.Name}}",
	{{end -}}
}

var {{$alias.UpSingular}}TableColumns = struct {
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}} string
	{{end -}}
}{
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}}: "{{$orig_tbl_name}}.{{$column.Name}}",
	{{end -}}
}

{{/* Generated where helpers for all types in the database */}}
// Generated where
{{- range .Table.Columns -}}
	{{- if (oncePut $.DBTypes .Type)}}
		{{$name := printf "whereHelper%s" (goVarname .Type)}}
type {{$name}} struct { field string }
func (w {{$name}}) EQ(x {{.Type}}) qm.QueryMod { return qmhelper.Where{{if .Nullable}}NullEQ(w.field, false, x){{else}}(w.field, qmhelper.EQ, x){{end}} }
func (w {{$name}}) NEQ(x {{.Type}}) qm.QueryMod { return qmhelper.Where{{if .Nullable}}NullEQ(w.field, true, x){{else}}(w.field, qmhelper.NEQ, x){{end}} }
func (w {{$name}}) LT(x {{.Type}}) qm.QueryMod { return qmhelper.Where(w.field, qmhelper.LT, x) }
func (w {{$name}}) LTE(x {{.Type}}) qm.QueryMod { return qmhelper.Where(w.field, qmhelper.LTE, x) }
func (w {{$name}}) GT(x {{.Type}}) qm.QueryMod { return qmhelper.Where(w.field, qmhelper.GT, x) }
func (w {{$name}}) GTE(x {{.Type}}) qm.QueryMod { return qmhelper.Where(w.field, qmhelper.GTE, x) }
		{{if isPrimitive .Type -}}
func (w {{$name}}) IN(slice []{{.Type}}) qm.QueryMod {
	values := make([]interface{}, 0, len(slice))
	for _, value := range slice {
		values = append(values, value)
	}
	return qm.WhereIn(fmt.Sprintf("%s IN ?", w.field), values...)
}
func (w {{$name}}) NIN(slice []{{.Type}}) qm.QueryMod {
	values := make([]interface{}, 0, len(slice))
	for _, value := range slice {
	  values = append(values, value)
	}
	return qm.WhereNotIn(fmt.Sprintf("%s NOT IN ?", w.field), values...)
}
		{{end -}}
	{{end -}}
	{{if .Nullable -}}
		{{- if (oncePut $.DBTypes (printf "%s.null" .Type))}}
		{{$name := printf "whereHelper%s" (goVarname .Type)}}
func (w {{$name}}) IsNull() qm.QueryMod { return qmhelper.WhereIsNull(w.field) }
func (w {{$name}}) IsNotNull() qm.QueryMod { return qmhelper.WhereIsNotNull(w.field) }
		{{end -}}
	{{end -}}
{{- end}}

var {{$alias.UpSingular}}Where = struct {
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}} whereHelper{{goVarname $column.Type}}
	{{end -}}
}{
	{{range $column := .Table.Columns -}}
	{{- $colAlias := $alias.Column $column.Name -}}
	{{$colAlias}}: whereHelper{{goVarname $column.Type}}{field: "{{$.Table.Name | $.SchemaTable}}.{{$column.Name | $.Quotes}}"},
	{{end -}}
}

{{- if .Table.IsJoinTable -}}
{{- else}}
// {{$alias.UpSingular}}Rels is where relationship names are stored.
var {{$alias.UpSingular}}Rels = struct {
	{{range .Table.FKeys -}}
	{{- $relAlias := $alias.Relationship .Name -}}
	{{$relAlias.Foreign}} string
	{{end -}}

	{{range .Table.ToOneRelationships -}}
	{{- $ftable := $.Aliases.Table .ForeignTable -}}
	{{- $relAlias := $ftable.Relationship .Name -}}
	{{$relAlias.Local}} string
	{{end -}}

	{{range .Table.ToManyRelationships -}}
	{{- $relAlias := $.Aliases.ManyRelationship .ForeignTable .Name .JoinTable .JoinLocalFKeyName -}}
	{{$relAlias.Local}} string
	{{end -}}{{/* range tomany */}}
}{
	{{range .Table.FKeys -}}
	{{- $relAlias := $alias.Relationship .Name -}}
	{{$relAlias.Foreign}}: "{{$relAlias.Foreign}}",
	{{end -}}

	{{range .Table.ToOneRelationships -}}
	{{- $ftable := $.Aliases.Table .ForeignTable -}}
	{{- $relAlias := $ftable.Relationship .Name -}}
	{{$relAlias.Local}}: "{{$relAlias.Local}}",
	{{end -}}

	{{range .Table.ToManyRelationships -}}
	{{- $relAlias := $.Aliases.ManyRelationship .ForeignTable .Name .JoinTable .JoinLocalFKeyName -}}
	{{$relAlias.Local}}: "{{$relAlias.Local}}",
	{{end -}}{{/* range tomany */}}
}

// {{$alias.DownSingular}}R is where relationships are stored.
type {{$alias.DownSingular}}R struct {
	{{range .Table.FKeys -}}
	{{- $ftable := $.Aliases.Table .ForeignTable -}}
	{{- $relAlias := $alias.Relationship .Name -}}
	{{$relAlias.Foreign}} *{{$ftable.UpSingular}} `{{generateTags $.Tags $relAlias.Foreign}}boil:"{{$relAlias.Foreign}}" json:"{{$relAlias.Foreign}}" toml:"{{$relAlias.Foreign}}" yaml:"{{$relAlias.Foreign}}"`
	{{end -}}

	{{range .Table.ToOneRelationships -}}
	{{- $ftable := $.Aliases.Table .ForeignTable -}}
	{{- $relAlias := $ftable.Relationship .Name -}}
	{{$relAlias.Local}} *{{$ftable.UpSingular}} `{{generateTags $.Tags $relAlias.Local}}boil:"{{$relAlias.Local}}" json:"{{$relAlias.Local}}" toml:"{{$relAlias.Local}}" yaml:"{{$relAlias.Local}}"`
	{{end -}}

	{{range .Table.ToManyRelationships -}}
	{{- $ftable := $.Aliases.Table .ForeignTable -}}
	{{- $relAlias := $.Aliases.ManyRelationship .ForeignTable .Name .JoinTable .JoinLocalFKeyName -}}
	{{$relAlias.Local}} {{printf "%sSlice" $ftable.UpSingular}} `{{generateTags $.Tags $relAlias.Local}}boil:"{{$relAlias.Local}}" json:"{{$relAlias.Local}}" toml:"{{$relAlias.Local}}" yaml:"{{$relAlias.Local}}"`
	{{end -}}{{/* range tomany */}}
}

// NewStruct creates a new relationship struct
func (*{{$alias.DownSingular}}R) NewStruct() *{{$alias.DownSingular}}R {
	return &{{$alias.DownSingular}}R{}
}

// {{$alias.DownSingular}}L is where Load methods for each relationship are stored.
type {{$alias.DownSingular}}L struct{}
{{end -}}

// ID gathering methods for self and relations
{{range $ind, $col := .Table.Columns -}}
	{{- $colAlias := $alias.Column $col.Name -}}
	{{if eq $colAlias "ID" -}}
// Slice utils for identifying columns
func (o *{{$alias.UpSingular}}Slice) Ids() []int {
	ids := map[int]bool{}
	for _, item := range *o {
		ids[item.ID] = true
	}

	out := []int{}
	for id, _ := range ids {
		out = append(out, id)
	}
	return out
}
	{{- end}}
	{{if eq $colAlias "UUID" -}}
func (o *{{$alias.UpSingular}}Slice) Uuids() []uuid.UUID {
	uuids := map[uuid.UUID]bool{}
	for _, item := range *o {
		uuids[item.UUID] = true
	}

	out := []uuid.UUID{}
	for uid, _ := range uuids {
		out = append(out, uid)
	}
	return out
}
func (o *{{$alias.UpSingular}}Slice) IdMap() map[int]*{{$alias.UpSingular}} {
    out := make(map[int]*{{$alias.UpSingular}}, len(*o))
	for _, item := range *o {
		out[item.ID] = item
	}
	return out
}
func (o *{{$alias.UpSingular}}Slice) UuidMap() map[uuid.UUID]*{{$alias.UpSingular}} {
    out := make(map[uuid.UUID]*{{$alias.UpSingular}}, len(*o))
	for _, item := range *o {
		out[item.UUID] = item
	}
	return out
}
func (o *{{$alias.UpSingular}}Slice) IntToUuidMap() map[int]uuid.UUID {
    out := make(map[int]uuid.UUID, len(*o))
	for _, item := range *o {
		out[item.ID] = item.UUID
	}
	return out
}
	{{- end}}
{{- end}}

{{range $ind, $fk := .Table.FKeys -}}
	{{- $colName := $alias.Column $fk.Column -}}
func (o *{{$alias.UpSingular}}Slice) {{$colName}}s() []int {
	ids := map[int]bool{}
	for _, item := range *o {
		{{if $fk.Nullable -}}
		if item.{{$colName}}.Valid {
			ids[item.{{$colName}}.Int] = true
		}
		{{- else}}
		ids[item.{{$colName}}] = true
		{{- end}}
	}

	out := []int{}
	for id, _ := range ids {
		out = append(out, id)
	}
	return out
}
func (o *{{$alias.UpSingular}}Slice) GroupBy{{$colName}}s() map[int]{{$alias.UpSingular}}Slice {
	ids := map[int]{{$alias.UpSingular}}Slice{}
	for _, item := range *o {
		{{if $fk.Nullable -}}
		if item.{{$colName}}.Valid {
			ids[item.{{$colName}}.Int] = append(ids[item.{{$colName}}.Int], item)
		}
		{{- else}}
		ids[item.{{$colName}}] = append(ids[item.{{$colName}}], item)
		{{- end}}
	}
	return ids
}
{{end -}}
