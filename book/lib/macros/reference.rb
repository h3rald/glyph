
macro :error_table do
	%{
		<table style="width:100%;">
			<tr>
				<th style="width:30%">Error Message</th>
				<th>Description</th>
			</tr>
			#{@value}
		</table>
	}
end

macro :ref_error do
	error, description = @params
	%{
		<tr>
			<td>#{error}</td>
			<td>#{description}</td>
		</tr>
	}
end

macro :"%>" do
	interpret "=>[#m_#@value|#@value] macro"
end

macro :"#>" do
	interpret "=>[#c_#@value|#@value] command"
end

macro :"$>" do
	val = @value.gsub /\./, "_"
	interpret "=>[#s_#{val}|#@value] setting"
end

macro :default do
	%{*Default Value:* @#@value@}
end

macro :"parameters" do
	interpret %{
		section[header[#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-1]}]

		<table style="width:100%;">
			<tr>
				<th style="width:30%">#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-2]}</th>
				<th>Description</th>
			</tr>
#{@value}
		</table>
		]
	}
end

macro :option do
	ident, desc = @params
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
	%{*Possible Values:* @#@value@}
end

macro :example do
	%{*Example:* @#@value@}
end

macro :examples do
	%{
*Examples:* 
#{@value.split("\n").map{|i| "@#{i}@\n"}.to_s}
	}
end

macro :aliases do
	%{*Aliases:* @#@value@}
end

macro :ref_macro do
	m_name, m_value = @params
	interpret %{
	section[header[@#{m_name}@|m_#{m_name}]
#{m_value}
	]
	}
end

macro :ref_config do
	m_name, m_value = @params
	default = Glyph::SYSTEM_CONFIG.get(m_name).to_yaml.gsub(/^---/, '')
	interpret %{
	section[header[@#{m_name}@|s_#{m_name.gsub(/\./, '_')}]
#{m_value}

	*Default (YAML):*
	code[=
#{default}
	=]
	]
	}
end

macro :issue do
	exact_parameters 2
	ident, desc = @params
	interpret %{
		tr[
			td[=>[http://github.com/h3rald/glyph/issues/closed#issue/#{ident}|##{ident}]]
			td[#{desc}]
		]
	}
end

macro :features do
	extra = (@name == :features) ? "Implemented" : "Fixed"
	interpret %{
		section[header[#{extra} #{@name.to_s.capitalize}]
			table[
				tr[
					th[ID]
					th[Description]
				]
				#@value
			]
		]
	}
end

macro :release do
	exact_parameters 3
	number, date, contents = @params
	interpret %{
		section[header[#{date} &ndash; Release #{number}]
			#{contents}
		]
	}
end

macro_alias :options => :parameters
macro_alias '-p' => :ref_error
macro_alias '-o' => :option
macro_alias :bugs => :features
