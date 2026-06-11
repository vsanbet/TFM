# con este script creamos la tabla con los nombres unicos
import os
import pandas as pd

def read_tsv(fich:str = None):
    if fich: 
        try:
            df = pd.read_csv(fich, sep = '\t')
            return df
        except Exception as e:
            print(f'Ha ocurrido un error: {e}')
    else:
        print('No se introdujo el nombre o ruta del fichero.')


def unique_reps_names(df=None, output_prefix='output'):
    if df is not None:
        # Filas únicas
        df_unicos = df[df.duplicated('name', keep=False) == False]

        # Filas repetidas
        df_repetidos = df[df.duplicated('name', keep=False) == True]

        df_unicos_filename = f'{output_prefix}_unicos.tsv'
        df_repetidos_filename = f'{output_prefix}_repetidos.tsv'

        # Guardar ambos archivos
        df_unicos.to_csv(df_unicos_filename, sep='\t', index=False)
        print(f'Fichero con nombres únicos creado: {df_unicos_filename}')
        
        df_repetidos.to_csv(df_repetidos_filename, sep='\t', index=False)
        print(f'Fichero con nombres repetidos creado: {df_repetidos_filename}')


def join_df(fich1:str = None, fich2:str = None):
    if fich1 and fich2:
        df1 = pd.read_csv(fich1, sep = '\t')
        df2 = pd.read_csv(fich2, sep= '\t')

        df1['Sample_Name'] = df1['Sample_Name'].astype(str)
        df2['Sample_Name'] = df2['Sample_Name'].astype(str)

        df_merged = pd.merge(df1, df2, on='Sample_Name', how='inner')
        #not_merged_df = df1 + df2 - df_merged


        df_merged.to_csv('joined_tables.tsv', sep = '\t', index = False)
        print('Fichero unificado creado.')

# quitas fastq
def del_fastq(ficher_fastq:str = None):
    if ficher_fastq:
        try:
            df = pd.read_csv(ficher_fastq, sep='\t')
            df.iloc[:, 0] = df.iloc[:, 0].astype(str).str.replace('.fastq.gz', '', regex=False)

            df.iloc[:, 0].to_csv('short_names.tsv', sep='\t', index = False)
            print('Fichero filtrado creado')

        except Exception as e:
            print(f'Ha ocurrido un error: {e}')


from thefuzz import process
def fuzz_try(fich1:str = None, fich2:str = None):
    if fich1 and fich2:
        try:
            lista1 = pd.read_csv(fich1, sep='\t').iloc[:, 0].dropna().astype(str).tolist()

            lista2 = pd.read_csv(fich2, sep='\t').iloc[:, 0].dropna().astype(str).tolist()


            result = {}
            for name in lista1:
                match = process.extractOne(name, lista2)
                result[name] = match
            

            with open('fuzz_name_match_final.tsv', 'w') as out_file:
                out_file.write(f"Sample_Name\tR1_fastqc_file\tmatch_score\tis substring[yes/no]\n")
                for name, match in result.items():
                    # decir si substring de string
                    matched_name, score = match
                    if name in matched_name:
                        out_file.write(f"{name}\t{matched_name}.fastq.gz\t{score}\tyes\n")

                    else:
                        out_file.write(f"{name}\t{matched_name}.fastq.gz\t{score}\tno\n")

                print('Fichero matches fuzz creado')            
        
        except Exception as e:
            print(f'Error: {e}')
    else:
        print('No hay ficheros webo')



if __name__ == '__main__':
    #lectura1 = read_tsv('/home/bettini/data/r1_names.tsv')
    #lectura2 = read_tsv('/home/bettini/data/emilia_names.tsv')

    # Crear los ficheros con sufijos únicos
    #fichs1 = unique_reps_names(lectura1, output_prefix='r1_names')
    #fichs2 = unique_reps_names(lectura2, output_prefix='emilia_names')

    # innerjoin
    final = join_df('fuzz_name_match_final.tsv', 'envios_alejandro.tsv')

    #new_fich = del_fastq('/home/bettini/data/reads_path.tsv')
    #fuzztry = fuzz_try('envios_alejandro.tsv', '/home/bettini/data/short_names.tsv' )
