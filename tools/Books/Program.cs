using BookLib;
namespace Books
{
    public class Program
    {
        static int Main(string[] args)
        {
            int argsCount=2;
            int bookId=0;
            
            try
            {
                if(args.Length < argsCount)
                {
                    Console.WriteLine($"Zadej {argsCount} parametry: <id knihy> <vystupni soubor>");
                    return 1;
                }
                if(!int.TryParse(args[0], out bookId))
                {
                    Console.WriteLine($"Zadany parametr {args[0]} neni cislo");
                    return 1;
                }

                var htmlHeader=$"<html><head><title>Book id: {bookId}</title><link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\"></head><body>";
                var htmlFooter=$"/<body></html>";
                var bookContent = LoveReadDownload.DownloadBook(bookId);

                var outputFn = args[1];

                File.WriteAllText(outputFn, $"{htmlHeader}{bookContent}{htmlFooter}");
                Console.WriteLine($"Kniha zapsana do souboru {outputFn}");

                return 0;
            }
            catch(Exception e)
            {
                Console.WriteLine($"Chyba: {e.Message}, {e.InnerException?.Message}");
                return 1;
            }
        }
    }
}
