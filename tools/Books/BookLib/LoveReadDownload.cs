namespace BookLib;
using System;
using System.Text;
using HtmlAgilityPack;


    public static class LoveReadDownload
    {
        const string bookServerPrefix = "http://loveread.ec/read_book.php";
        static string bookTextSelector = "descendant::td[contains(@class,'tb_read_book')]/div[3]";
        static string pageCountSelector = "descendant::div[contains(@class,'navigation')]/a[(last() - 1)]";

        static string nextPageFormSelector = "//div/form/..";

        public static string DownloadBook(int bookId, string baseUrl=bookServerPrefix)
        {
            var strBuilder = new StringBuilder();
            var maxPages = GetMaxPageInBook(baseUrl, bookId);

            using (var progress = new ProgressBar()) {
			
                Console.WriteLine("Stahuji...");
                for(int i=1; i <= maxPages;i++)
                {
                    progress.Report((double) i / maxPages);
                    strBuilder.Append(GetPageInBook(bookId, i,baseUrl));
                }
                Console.WriteLine();
                Console.WriteLine("Kniha stazena");
            }
            return strBuilder.ToString();
        }   

        static string GetPageInBook(int bookId, int pageNum, string baseUrl=bookServerPrefix)
        {
            var strBuilder = new StringBuilder();

            var Webget = new HtmlWeb();
            
            var provider = CodePagesEncodingProvider.Instance;
            Encoding.RegisterProvider(provider);

            Webget.OverrideEncoding = Encoding.GetEncoding("windows-1251");

            var doc = Webget.Load($"{baseUrl}?id={bookId}&p={pageNum}");
            doc.OptionOutputAsXml=true;
            doc.OptionFixNestedTags = true;
            doc.OptionDefaultStreamEncoding = Encoding.UTF8;

            var nodes = doc.DocumentNode.SelectNodes(bookTextSelector);

            foreach(var node in nodes)
            {
                var nextPageNodes = node.SelectNodes(nextPageFormSelector);
                foreach(var nextPageNode in nextPageNodes)
                {
                    nextPageNode?.Remove();
                }
                strBuilder.Append(node.InnerHtml);
            }
            return strBuilder.ToString();
        }
        static int GetMaxPageInBook(string baseUrl, int bookId)
        {
            int maxPage=1;

            var Webget = new HtmlWeb();
            var provider = CodePagesEncodingProvider.Instance;
            Encoding.RegisterProvider(provider);

            Webget.OverrideEncoding = Encoding.GetEncoding("windows-1251");
        
            var doc = Webget.Load($"{baseUrl}?id={bookId}");
            doc.OptionOutputAsXml=true;
            doc.OptionFixNestedTags = true;
            doc.OptionDefaultStreamEncoding = Encoding.UTF8;

            var nodes = doc.DocumentNode.SelectNodes(pageCountSelector);

            if(nodes?.Count!=1)
            {
                Console.WriteLine("Cannot parse page count");
                return 1;
            }

            if(!int.TryParse(nodes[0].InnerHtml, out maxPage))
            {
                Console.WriteLine($"Cannot parse page count, loaded {nodes[0].InnerHtml}");
                return 1;
            }

            Console.WriteLine($"Celkem stran: {maxPage}");
            return maxPage;
        }
    }

