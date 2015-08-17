require 'net/https'
require 'json'
require 'csv'
require 'pp'

module Ruboty
    module Handlers
        class Meshi < Base
            GITHUB_API = 'https://api.github.com'
            MESHI_LIST_URL  = 'https://gist.github.com/mopp/8ab50020202834c96652'

            on(
                /meshi.*/,
                name: "meshi",
                description: "Maekawa Meshi-Recommendation\n\texample: @maekawa meshi ラーメン"
            )

            def gistParse(url)
                JSON.parse(Net::HTTP.get(URI.parse(GITHUB_API + "/gists/#{url.split('/')[-1]}")))
            end

            def meshi(message)
                # Get meshi list urls
                meshiUrls = (gistParse(MESHI_LIST_URL))['files']['MeshiUrls']['content'].split("\n")

                # Concatenation
                csvStr = ''
                meshiUrls.each do |url|
                    # Get meshi list
                    result = gistParse(url)
                    meshiFiles = result['files']
                    meshiFiles.keys.each do | file |
                        file    = meshiFiles[file]
                        csvStr += file['content'].gsub(/,\s?/, ',')
                    end
                end

                searchStrs = message.body.sub(/^@*#{message.robot.name}:* meshi /, '').strip.split(' ')
                    meshis = CSV.parse(csvStr,  skip_blanks: true)
                matchMeshi = meshis.select do |row|
                    row if searchStrs.all? do |str|
                        row.inspect.include?(str)
                    end
                end

                return message.reply("そんなめしやはしらねぇにゃ") if matchMeshi.length == 0

                lines = matchMeshi.map do |row|
                    sprintf("%s (%s)\n  時間: %s\n  備考: %s", row[0], row[1], row[2], row[3])
                end

                message.reply("登録リストにあるのはこれだにゃ")
                message.reply(lines.join("\n"))
            end
        end
    end
end
