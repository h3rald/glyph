
macro :error_table do
	%{
		<table style="width:100%;">
			<tr>
				<th style="width:30%">Error Message</th>
				<th>Description</th>
			</tr>
			#{value}
		</table>
	}
end

macro :ref_error do
	error, description = params
	%{
		<tr>
			<td>#{error}</td>
			<td>#{description}</td>
		</tr>
	}
end

macro :"%>" do
	interpret "=>[#m_#{value.gsub(/[^a-z0-1_-]/, '_')}|#{value}] macro"
end

macro :"#>" do
	interpret "=>[#c_#{value}|#{value}] command"
end

macro :"$>" do
	val = value.gsub /\./, "_"
	interpret "=>[#s_#{val}|#{value}] setting"
end

macro :default do
	%{*Default Value:* @#{raw_value}@}
end

macro :"parameters" do
	interpret %{
		section[header[#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-1]}]

		<table style="width:100%;">
			<tr>
				<th style="width:30%">#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-2]}</th>
				<th>Description</th>
			</tr>
#{value}
		</table>
		]
	}
end

macro :option do
	ident = param(0)
	desc = param(1)
	%{
		<tr>
			<td><notextile>-#{ident[0..0]} (--#{ident})</notextile></td>
			<td>
#{desc}
			</td>
		</tr>
	}
end

macro :values do
	%{*Possible Values:* @#{value}@}
end

macro :example do
	%{*Example:* <code>#{value}</code>}
end

macro :examples do
	%{
*Examples:* 
#{value.split("\n").map{|i| "@#{i}@\n"}.to_s}
	}
end

macro :aliases do
	%{*Aliases:* @#{value}@}
end

macro :ref_macro do
	m_name = param(0)
 	m_value = param(1)
	interpret %{
	section[
@title[#{m_name}]
@id[m_#{m_name.gsub(/[^a-z0-1_-]/, '_')}]
#{m_value}
	]
	}
end

macro :ref_config do
	m_name = param(0)
	m_value = param(1)
	default = Glyph::SYSTEM_CONFIG.get(m_name).to_yaml.gsub(/^---/, '')
	default = "nil" if default.blank?
	interpret %{tr[
		td[codeph[#{m_name}] #[s_#{m_name.gsub(/\./, '_')}]]
		td[#{m_value}]
		td[
			code[=
#{default}
			=]
		]
	]}
end

macro :config_table do
	interpret %{table[
			tr[
				th[Name]
				th[Description]
				th[Default (YAML)]
			]
			#{value}
		]}
end


macro_alias :options => :parameters
macro_alias '-p' => :ref_error
macro_alias '-o' => :option
