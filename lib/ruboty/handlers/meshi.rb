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

            def formatStr(row)
                sprintf("%s (%s)\n  時間  : %s\n  定休日: %s\n  備考  : %s", row[0], row[1], row[2], row[3], row[4])
            end

            def formatCsvStr(csv)
                csv.map do |row|
                    formatStr(row)
                end
            end

            def meshi(message)
                meshiUrls = (gistParse(MESHI_LIST_URL))['files']['MeshiUrls']['content'].split("\n")

                # CSV文字列連結.
                csvStr = ''
                meshiUrls.each do |url|
                    # Get meshi list
                    result = gistParse(url)
                    meshiFiles = result['files']
                    meshiFiles.keys.each do | file |
                        file    = meshiFiles[file]
                        csvStr += (file['content'].gsub(/,\s?/, ',') + "\n")
                    end
                end

                # CSV作成
                meshis = CSV.parse(csvStr,  skip_blanks: true)
                meshis.delete_if do |row|
                    row[0] == 'name'
                end

                searchStrs = message.body.sub(/^@*#{message.robot.name}:* meshi /, '').split(' ')

                # 全部表示.
                if searchStrs.include?('*') || searchStrs.include?('all')
                    message.reply("これで全部にゃ")
                    message.reply(formatCsvStr(meshis).join("\n"))
                    return
                end

                # check random
                randomFlag = false
                if searchStrs.include?('random')
                    randomFlag = true
                    searchStrs.delete('random')
                end

                if searchStrs.length == 0
                    # 乱択飯屋
                    message.reply("仕方ないからみくが選んであげるにゃ！\nここがいいにゃ！")
                    message.reply(formatStr(meshis.sample))
                else
                    matchMeshi = meshis.select do |row|
                        row if searchStrs.all? do |str|
                            row.inspect.include?(str)
                        end
                    end

                    return message.reply("そんなめしやはしらねぇにゃ") if matchMeshi.length == 0

                    if randomFlag
                        message.reply("[#{searchStrs.join(' ')}]に当てはまるところからみくが決めてあげるにゃ！\nここがいいにゃ！")
                        message.reply(formatStr(matchMeshi.sample))
                    else
                        message.reply("登録リストにあるのはこれだにゃ")
                        message.reply(formatCsvStr(matchMeshi).join("\n"))
                    end
                end
            end
        end
    end
end
