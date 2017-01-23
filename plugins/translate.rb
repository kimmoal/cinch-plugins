class Translate
	include Cinch::Plugin

	match /translate (.*)/iu

	def execute(m, message)
		begin
			url = open("https://api.datamarket.azure.com/Bing/MicrosoftTranslator/v1/Translate?Text=%27#{URI.escape(message)}%27&To=%27en%27",
                        :http_basic_authentication=>[Conf[:azure][:user], Conf[:azure][:pass]])
			url = Nokogiri::XML(url)
			result = url.xpath("//d:Text").text
			m.reply "#{result}"
		rescue
			m.reply "#{m.user.nick}: translation failed"
		end
	end
end
